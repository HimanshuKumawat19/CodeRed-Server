import httpx
import asyncio
import json
import base64
from sqlalchemy.orm import Session
from sqlalchemy.future import select

# --App Specific imports-- 
# Import Database Model
from app.models.submission import Submission
from app.models.problems import Problems
from app.models.test_cases import TestCases
# Import Pydantic Schemaas
from app.schemas.submission import CodeRunRequest,SolutionSubmitRequest
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
    # Fix 8-print bug
    if total_len > 0 and total_len % 8 == 0:
        unit_length = total_len // 8
        unit_1 = clean_str[0:unit_length]
        unit_2 = clean_str[unit_length : unit_length * 2]
        if unit_1 == unit_2:
            return unit_1
            
    return clean_str

async def execute_judge0(client, source_code, language_id, stdin):
    source_b64 = base64.b64encode(source_code.encode()).decode()
    stdin_b64 = base64.b64encode(stdin.encode()).decode()

    payload = {
        "source_code": source_b64,
        "language_id": language_id,
        "stdin": stdin_b64,
        "number_of_runs": 1
    }

    headers = {
        "content-type": "application/json",
        "X-RapidAPI-Key": RAPIDAPI_KEY,
        "X-RapidAPI-Host": RAPIDAPI_HOST
    }

    try:
        # --- CREATE SUBMISSION ---
        create_resp = await client.post(
            f"{JUDGE0_URL}?base64_encoded=true&wait=false",
            json=payload,
            headers=headers
        )
        create_resp.raise_for_status()

        token = create_resp.json().get("token")
        if not token:
            return {"error": "No token returned by Judge0"}

        # --- POLL FOR RESULT ---
        while True:
            poll_resp = await client.get(
                f"{JUDGE0_URL}/{token}?base64_encoded=true",
                headers=headers
            )
            poll_resp.raise_for_status()

            result = poll_resp.json()
            status_id = result.get("status", {}).get("id")

            if status_id in (1, 2):  # In Queue, Processing
                await asyncio.sleep(1)
                continue

            # Decode Base64
            for field in ("stdout", "stderr", "compile_output"):
                if result.get(field):
                    result[field] = base64.b64decode(result[field]).decode('utf-8', "ignore")

            # Clean stdout
            result["stdout"] = clean_stdout(result.get("stdout"))
            return result

    except Exception as e:
        return {"error": "Judge0 API Error", "detail": str(e)}


async def run_code_service(db: Session, run_request: CodeRunRequest):
    """
    Run API: 
    1. Fetches test cases from DB.
    2. Filters for ONLY Public (non-hidden) cases.
    3. Runs ALL of them.
    4. Returns detailed results for the Frontend.
    """
    print(f"Executing 'Run' (Public Tests) for Problem {run_request.problem_id}")

    # 1. Fetch Test Cases from DB
    query = select(TestCases).where(TestCases.problem_id == run_request.problem_id)
    result = await db.execute(query)
    test_case_record = result.scalars().first()

    if not test_case_record or not test_case_record.test_cases:
        return {"error": "Test cases not found for this problem"}

    # 2. Parse and Filter for PUBLIC (Hidden=False)
    all_test_cases = test_case_record.test_cases
    if isinstance(all_test_cases, str):
        all_test_cases = json.loads(all_test_cases)

    # Filter: Keep only where hidden is False (or doesn't exist)
    public_test_cases = [tc for tc in all_test_cases if tc.get("hidden", False) is False]

    if not public_test_cases:
        return {"error": "No public test cases found to run."}

    # 3. Execution Loop
    run_results = []
    all_passed = True
    
    async with httpx.AsyncClient() as client:
        for i, case in enumerate(public_test_cases):
            input_data = case.get("input")
            expected_output = case.get("output", "").strip()
            
            # Run the Code
            api_result = await execute_judge0(
                client, 
                run_request.source_code, 
                run_request.language_id, 
                input_data
            )

            # Extract Details
            if "error" in api_result:
                return {"error": "System Error", "detail": api_result.get("detail")}

            stdout_actual = api_result.get("stdout", "")
            stderr = api_result.get("stderr", "")
            compile_output = api_result.get("compile_output", "")
            verdict = api_result.get("status", {}).get("description")

            # Check Logic
            status = "Passed"
            if verdict != "Accepted":
                status = "Error" # Runtime Error, Compilation Error, etc.
                all_passed = False
            elif stdout_actual != expected_output:
                status = "Failed" # Wrong Answer
                all_passed = False

            # Append detailed result for this test case
            run_results.append({
                "test_case_index": i + 1,
                "status": status,
                "input": input_data,
                "expected_output": expected_output,
                "actual_output": stdout_actual,
                "stderr": stderr,
                "compile_output": compile_output
            })

    # 4. Final Response
    return {
        "verdict": "Accepted" if all_passed else "Wrong Answer",
        "total_public_cases": len(public_test_cases),
        "results": run_results
    }
        

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
    )
    result = await db.execute(query)
    test_case_record = result.scalars().first()

    if not test_case_record or not test_case_record.test_cases:
        return {"error":"Test cases not found for this problem"}

    # Ensure test_cases is a list (SQLAlchemy + JSONB usually returns a Python list directly)
    all_test_cases = test_case_record.test_cases
    # Fallback if it comes as string (rare with JSONB type but possible)
    if isinstance(all_test_cases,str):
        all_test_cases = json.loads(all_test_cases)

    #Create the Submission Record 
    new_submission = Submission(
        user_id=user_id,
        language_id=submission_in.language_id,
        source_code=submission_in.source_code,
        problem_id=submission_in.problem_id,
        verdict="Judging",
        total_test_cases=len(all_test_cases),
        test_cases_passed=0
    )
    try:
        db.add(new_submission)
        await db.commit()
        await db.refresh(new_submission)
    except Exception as e:
        await db.rollback()
        return {"error":f"Failed to create submission record: {e}"}
    
    # Execution Loop
    final_verdict = "Accepted"
    error_message = None

    async with httpx.AsyncClient() as client:
        for i, case in enumerate(all_test_cases):
            input_data = case.get("input")
            expected_output = case.get("output","").strip()
            is_hidden = case.get("hidden",False)

            print(f"Running test case {i+1}/{len(all_test_cases)} (Hidden : {is_hidden})")

            # Run code
            result = await execute_judge0(
                client,
                submission_in.source_code,
                submission_in.language_id,
                input_data
            )

            time_value = result.get("time")
            memory_value = result.get("memory")

            new_submission.execution_time = float(time_value) if time_value is not None else 0.0
            new_submission.memory_used = int(float(memory_value)) if memory_value is not None else 0
   
            if "error" in result:
                final_verdict = "System Error"
                error_message = result.get("detail","Unknown API Error")
                break

            judge_verdict = result.get("status",{}).get("description")
            stdout_clean = result.get("stdout","")

            if judge_verdict != "Accepted":
                final_verdict = judge_verdict  # e.g. 'Runtime Error'

                # SECURITY: If hidden, don't show stderr (might leak info)
                if is_hidden:
                    error_message = "Runtime Error on Hidden Test Case"
                else:
                    error_message = result.get("stderr") or result.get("compile_output")
                break

            if stdout_clean != expected_output:
                final_verdict = "Wrong Answer"

                # SECURITY: If hidden, generic message. If public, show diff.
                if is_hidden:
                    error_message = "Wrong Answer on Hidden Test Case"
                else:
                    error_message = f"Test Case {i+1} Failed.\nExpected: '{expected_output}'\nGot: '{stdout_clean}"
                break

            # Success for this case   
            new_submission.test_cases_passed = i+1

    print(f"Final Verdict: {final_verdict}")
    new_submission.verdict = final_verdict
    new_submission.stderr = error_message
    

    await db.commit()
    return new_submission