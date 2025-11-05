import httpx
import time
import json

# --- 1. PASTE YOUR CONFIG HERE ---
# (From your RapidAPI screenshot)
RAPIDAPI_KEY = "9898502698msh9c488abca06ee0ap17e14ajsnfab6436a89db" 
RAPIDAPI_HOST = "judge0-extra-ce.p.rapidapi.com"
JUDGE0_URL = "https://judge0-extra-ce.p.rapidapi.com/submissions"

def test_code_submission():
    """
    A single function to test the full Judge0 submission and polling process.
    """
    
    print("🚀 Starting test...")

    # --- 2. DEFINE THE CODE TO RUN ---
    # This is a simple C "Hello World"
    payload = {
        "source_code": "#include <stdio.h>\n\nint main(void) {\n  printf(\"hello, world\\n\");\n  return 0;\n}",
        "language_id": 6, # 50 is C (GCC 7.4.0)
        "stdin": None,
        "number_of_runs": 1
    }

    # --- 3. SET THE HEADERS ---
    headers = {
        "content-type": "application/json",
        "X-RapidAPI-Key": RAPIDAPI_KEY,
        "X-RapidAPI-Host": RAPIDAPI_HOST
    }

    # --- 4. POST THE SUBMISSION ---
    print(f"Submitting to {JUDGE0_URL}...")
    try:
        response = httpx.post(f"{JUDGE0_URL}?base64_encoded=false&wait=false", json=payload, headers=headers)
        response.raise_for_status() # Raise an error if the request failed
        
        token = response.json().get("token")
        if not token:
            print("❌ ERROR: Failed to get submission token.")
            print(response.json())
            return

        print(f"✅ Submission successful! Token: {token}")

    except httpx.HTTPStatusError as e:
        print(f"❌ ERROR: Failed to create submission.")
        print(f"Status code: {e.response.status_code}")
        print(f"Response: {e.response.text}")
        return
    except Exception as e:
        print(f"❌ An unexpected error occurred: {e}")
        return

    # --- 5. POLL FOR THE RESULT ---
    result = None
    while True:
        try:
            print("...Polling for result...")
            get_response = httpx.get(f"{JUDGE0_URL}/{token}?base64_encoded=false", headers=headers)
            get_response.raise_for_status()
            
            result = get_response.json()
            status_id = result.get("status", {}).get("id")

            # 1 = "In Queue", 2 = "Processing"
            if status_id == 1 or status_id == 2:
                time.sleep(1) # Wait 1 second and poll again
                continue
            
            # 3 or more = Done!
            break # Exit the loop

        except httpx.HTTPStatusError as e:
            print(f"❌ ERROR: Failed to retrieve submission.")
            print(f"Status code: {e.response.status_code}")
            print(f"Response: {e.response.text}")
            return
        except Exception as e:
            print(f"❌ An unexpected error occurred while polling: {e}")
            return

    # --- 6. PRINT THE FINAL RESULT ---
    print("\n🎉 --- FINAL RESULT --- 🎉")
    # pretty-print the JSON
    print(json.dumps(result, indent=4))

    # Check for success
    if result.get("status", {}).get("description") == "Accepted":
        print("\n✅ Test Passed! stdout: ", result.get("stdout"))
    else:
        print("\n❌ Test Finished (but not 'Accepted'). Check output.")

# --- RUN THE TEST ---
if __name__ == "__main__":
    test_code_submission()