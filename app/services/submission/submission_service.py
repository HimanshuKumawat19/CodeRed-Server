import httpx
import time
import asyncio
from sqlalchemy.orm import Session

# --App Specific imports-- 
# Import Database Model
from app.models.submission import Submission
# Import Pydantic Schemaas
from app.schemas.submission import SubmissionCreate,SubmissionUpdate
# Import app's settings
from app.config import settings

# -- Configuration for Judge0 --
RAPIDAPI_KEY = settings.RAPIDAPI_KEY
RAPIDAPI_HOST = settings.RAPIDAPI_HOST
JUDGE0_URL = f"https://{RAPIDAPI_HOST}/submissions"

# Fixes the 8-print bug from the free Judge0 Extra API for temperory
def clean_stdout(stdout:str | None) -> str | None:
    if not stdout:
        return None
    
    clean_str = stdout.rstrip('\n')

    if not clean_str:
        return None
    
    unit_length = len(clean_str)//8

    real_stdout = clean_str[0:unit_length]

    # if not real_stdout.endswith('\n'):
    #     real_stdout += '\n'
    
    return real_stdout

async def create_and_run_submission(db: Session,submission_in:SubmissionCreate, user_id: int):
    """
    - Main Service Function
    1. Create a "Pending" submission
    2. call judge0 API to get a token
    3. Polls for the results
    4. Updates the database with the final result
    """

    new_submission = Submission(
        user_id = user_id,
        language_id = submission_in.language_id,
        source_code = submission_in.source_code,
        problem_id = submission_in.problem_id,
        match_id = submission_in.match_id,
        verdict="Pending"
    )

    try:
        db.add(new_submission)
        await db.commit()
        await db.refresh(new_submission)
    except Exception as e:
        await db.rollback()
        print(f"Databse error on submission create: {e}")
        return {"error":"Failed to create submission record"}

    # new_submission.Submission_id is now available
    print(f"Created pending submission with ID: {new_submission.Submission_id}")

    # --- Call RapidAPI and Get Token ---

    async with httpx.AsyncClient() as client:
        
        #  Prepare the payload for Judge0
        #  We get the data from the 'submission_in' Pydantic model
        payload = { 
            "source_code": submission_in.source_code,
            "language_id": submission_in.language_id,
            "stdin": submission_in.stdin,
            "number_of_runs": 1
        }

        # Prepare the headers(using our config variables)
        headers= {
            "content-type": "application/json",
            "X-RapidAPI-Key": RAPIDAPI_KEY,
            "X-RapidAPI-Host": RAPIDAPI_HOST
        }

        # POST the submission to Judge0
        try:
            print(f"Submitting to Judge0 for submissio ID: {new_submission.Submission_id}...")

            # 'await' pauses the function here until the API call is complete
            response = await client.post(
                f"{JUDGE0_URL}?base64_encoded=false&wait=false",
                json=payload,
                headers=headers,
                timeout=10.0
            )

            # Exception for 4xx or 5xx errors (like 403,422)
            response.raise_for_status()

            token = response.json().get("token")

            if not token:
                # API call succedded but no token
                raise Exception("Failed to get submission token from Judge0.")
            
            # SUCCESS! save the token to Database
            new_submission.token = token
            await db.commit()
            print(f"Got token: {token}")
        
        except (httpx.HTTPStatusError,httpx.RequestError) as e:
            # This catches API errors (like 403, 500) or network errors (timeout)
            print(f"Error submitting to Judge0:{e}")
            # Update our database row to show it failed
            new_submission.verdict = "System Error"
            new_submission.stderr = str(e)
            await db.commit()
            return {"error": str(e)}

        except Exception as e:
            # Catch other unexpected error(like no token)
            new_submission.verdict = "Internal Error"
            new_submission.stderr = str(e)
            await db.commit()
            return {"error":str(e)}
        
        # Loop until the job is no longer "In Queue" or "Processing"
        final_result = None
        while True:
            try:
                print(f"Polling for result (token:{token})...")

                # 'await' for pauses the function
                response = await client.get(
                    f"{JUDGE0_URL}/{token}?base64_encoded=false",
                    headers=headers,
                    timeout=5.0          
                )

                result = response.json()
                status_id = result.get("status",{}).get("id")

                # 1 = "In Queue" , 2 = "Processing"
                if status_id == 1 or status_id == 2:
                    await asyncio.sleep(1)  # wait for 1 second
                    continue

                # 3 or more = Done! (Accepted,WA,Compile Error)
                final_result = result
                print(f"Got final result for token {token}:{final_result.get('status',{}).get('description')}")
                break # exit the while loop

            except (httpx.HTTPStatusError,httpx.RequestError) as e:
                print(f"Error polling Judge0: {e}")
                new_submission.verdict = "System Error"
                new_submission.stderr = f"Error While Polling: {e}"
                await db.commit()
                return {"error": str(e)}

            # --- Update Database with Final Result

        try:
            update_data = SubmissionUpdate(
                verdict=final_result.get("status",{}).get("description","Error"),
                status_id = final_result.get("status",{}).get("id"),
                execution_time = final_result.get("time"),
                memory_used=final_result.get("memory"),
                stdout=clean_stdout(final_result.get("stdout")),
                stderr = final_result.get("stderr"),
                compile_output=final_result.get("compile_output")
            )

            # Update the submission in the database
            for key, value in update_data.model_dump(exclude_unset=True).items():
                setattr(new_submission,key,value)
            
            await db.commit()
            await db.refresh(new_submission)
        
        except Exception as e:
            print(f"Error updating database with final result: {e}")
            new_submission.verdict = "DB Update Error"
            new_submission.stderr = f"Failed to save result: {e}"
            await db.commit()
            return {"error":"Failed to update submission with results"}

        # --Finished--
        # Return the complete, updated submission object to the API
        return new_submission
