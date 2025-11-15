import httpx
import time
import asyncio
from sqlalchemy.orm import Session
from sqlalchemy.future import select

# --App Specific imports-- 
# Import Database Model
from app.models.submission import Submission
from app.models.problems import Problems
from app.models.test_cases import TestCases
# Import Pydantic Schemaas
from app.schemas.submission import SubmissionCreate,SubmissionUpdate,CodeRunRequest,SolutionSubmitRequest
# Import app's settings
from app.config import settings

# -- Configuration for Judge0 --
RAPIDAPI_KEY = settings.RAPIDAPI_KEY
RAPIDAPI_HOST = settings.RAPIDAPI_HOST
JUDGE0_URL = f"https://{RAPIDAPI_HOST}/submissions"

# Fixes the 8-print bug from the free Judge0 Extra API for temperory
def clean_stdout(stdout:str | None) -> str | None:
    """
    Safely cleans stdout from Judge0.
    This specifically looks for and fixes the 8-repeat bug.
    """
    if not stdout:
        return ""  # Return an empty string if stdout is None

    clean_str = stdout.strip()
    if not clean_str:
        return ""  # String was just whitespace

    total_len = len(clean_str)

    # --- Start of 8-print bug detection ---
    if total_len > 0 and total_len % 8 == 0:
        unit_length = total_len // 8
        unit_1 = clean_str[0:unit_length]
        unit_2 = clean_str[unit_length : unit_length * 2]
        if unit_1 == unit_2:
            return unit_1
    # --- End of bug detection ---

    # ✅ Always return the cleaned string if no bug found
    return clean_str

async def run_code_service(run_request: CodeRunRequest):
    """
    Runs code temporarily wihtout saving to the database
    """
    print(f"Executing a 'Run' operation for language {run_request.language_id}...")

    async with httpx.AsyncClient() as client:
        payload = {
            "source_code":run_request.source_code,
            "language_id":run_request.language_id,
            "stdin":run_request.stdin,
            "number_of_runs":1
        }
        headers = {
            "content-type": "application/json",
            "X-RapidAPI-Key": RAPIDAPI_KEY,
            "X-RapidAPI-Host": RAPIDAPI_HOST
        }

        try:
            # get token
            response = await client.post(
                f"{JUDGE0_URL}?base64_encoded=false&wait=false",
                json=payload,headers=headers,timeout=10.0
            )
            response.raise_for_status()
            token = response.json().get("token")
            if not token:
                return {"error":"Failed to get submission token"}
            
            # POLLING loop
            while True:
                response = await client.get(
                    f"{JUDGE0_URL}/{token}?base64_encoded=false",
                    headers=headers,
                    timeout=5.0
                )
                response.raise_for_status()
                result = response.json()
                status_id = result.get("status",{}).get("id")

                if status_id == 1 or status_id == 2:
                    await asyncio.sleep(1)
                    continue

                # Got the result! Clean the stdout
                result["stdout"] = clean_stdout(result.get("stdout"))
                return result  # return raw Judge0 result
        
        except (httpx.HTTPStatusError,httpx.RequestError) as e:
            print(f"API Error on /run: {e}")
            return {"error":"System Error","detail":str(e)}
        except Exception as e:
            print(f"Internal Error on /run: {e}")
            return {"error":"Internal Error","detail":str(e)}
        

# For /submit endpoint
async def submit_solution_service(
    db:Session, 
    submission_in:SolutionSubmitRequest,
    user_id: int
):
    # runs code against hidden test cases and saves to the database
    # for "Submit"

    print(f"Executing a 'Submit for problem {submission_in.problem_id} by user {user_id}...")

    query = (
        select(TestCases)
        .where(TestCases.problem_id == submission_in.problem_id)
        .where(TestCases.is_hidden == True)
    )
    result = await db.execute(query)
    hidden_test_cases = result.scalars().all()

    if not hidden_test_cases:
        return {"error":"No hidden test cases found for this problem"}

    new_submission = Submission(
        user_id=user_id,
        language_id=submission_in.language_id,
        source_code=submission_in.source_code,
        problem_id=submission_in.problem_id,
        verdict="Judging",
        total_test_cases=len(hidden_test_cases)
    )
    try:
        db.add(new_submission)
        await db.commit()
        await db.refresh(new_submission)
    except Exception as e:
        await db.rollback()
        return {"error":f"Failed to create submission record: {e}"}

    async with httpx.AsyncClient() as client:
        for i, case in enumerate(hidden_test_cases):
            print(f"Running test case {i+1}/{len(hidden_test_cases)}...")

            payload = {
                "source_code":submission_in.source_code,
                "language_id":submission_in.language_id,
                "stdin":case.input_data,
                "number_of_runs":1
            }
            headers = {
                "content-type":"application/json",
                "X-RapidAPI-Key":RAPIDAPI_KEY,
                "X-RapidAPI-Host":RAPIDAPI_HOST
            }
            try:
                response = await client.post(
                    f"{JUDGE0_URL}?base64_encoded=false&wait=false",
                    json=payload,
                    headers=headers,
                    timeout=10.0
                )
                response.raise_for_status()
                token = response.json().get("token")
                if not token: raise Exception("No token from Judge0")

                final_result = None
                while True:
                    response = await client.get(
                        f"{JUDGE0_URL}/{token}?base64_encoded=false",
                        headers=headers,
                        timeout=5.0
                    )
                    response.raise_for_status()
                    result = response.json()
                    status_id = result.get("status",{}).get("id")
                    if status_id ==1 or status_id ==2:
                        await asyncio.sleep(1)
                        continue
                    final_result = result
                    break
            
            except (httpx.HTTPStatusError, httpx.RequestError) as e:
                print(f"API Error on test case {i+1}: {e}")
                new_submission.verdict = "System Error"
                new_submission.stderr = f"Error on test case {i+1}: {e}"
                await db.commit()
                return new_submission # Stop on system error
            except Exception as e:
                print(f"Polling Error on test case {i+1}: {e}")
                new_submission.verdict = "Internal Error"
                new_submission.stderr = f"Error polling test case {i+1}: {e}"
                await db.commit()
                return new_submission
            
            verdict = final_result.get("status",{}).get("description","Error")
            stdout_clean = clean_stdout(final_result.get("stdout"))

            if verdict !="Accepted":
                print(f"Test Cases{i+1} FAILED. Verdict: {verdict}")
                new_submission.verdict = verdict
                new_submission.stderr = final_result.get("stderr")
                new_submission.compile_output = final_result.get("compile_output")
                await db.commit()
                return new_submission
            
        
            expected_clean = case.expected_output.strip() if case.expected_output else ""

            if stdout_clean != expected_clean:
                print(f"Test case {i+1} FAILED. Verdict: Wrong Answer")
                new_submission.verdict = "Wrong Answer"
                new_submission.stderr = f"Test Case {i+1} Failed. Expected: '{expected_clean}', Got: '{stdout_clean}'"
                await db.commit()
                return new_submission
            
            print(f"Test case {i+1} PASSED.")
            new_submission.test_cases_passed = i +1
            await db.commit()


    print("All test cases passed!")
    new_submission.verdict = "Accepted"
    await db.commit()
    return new_submission