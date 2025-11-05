import httpx
import json

# --- 1. PASTE YOUR CONFIG HERE ---
RAPIDAPI_KEY = "9898502698msh9c488abca06ee0ap17e14ajsnfab6436a89db"
RAPIDAPI_HOST = "judge0-extra-ce.p.rapidapi.com"
LANGUAGES_URL = "https://judge0-extra-ce.p.rapidapi.com/languages"

def get_languages():
    """
    Fetches and prints all available languages and their IDs.
    """
    print("🚀 Fetching all available languages...")

    # --- 2. SET THE HEADERS ---
    headers = {
        "X-RapidAPI-Key": RAPIDAPI_KEY,
        "X-RapidAPI-Host": RAPIDAPI_HOST
    }

    # --- 3. CALL THE /LANGUAGES ENDPOINT ---
    try:
        response = httpx.get(LANGUAGES_URL, headers=headers)
        response.raise_for_status() # Raise an error if the request failed
        
        languages = response.json()
        
        print("\n✅ --- AVAILABLE LANGUAGES --- ✅")
        # Pretty-print the JSON
        print(json.dumps(languages, indent=4))
        
        print("\n--- Common IDs ---")
        for lang in languages:
            if "C (GCC" in lang["name"]:
                print(f"Found C (GCC): ID = {lang['id']}")
            if "Python" in lang["name"]:
                print(f"Found Python: ID = {lang['id']}")
            if "JavaScript" in lang["name"]:
                print(f"Found JavaScript: ID = {lang['id']}")

    except httpx.HTTPStatusError as e:
        print(f"❌ ERROR: Failed to fetch languages.")
        print(f"Status code: {e.response.status_code}")
        print(f"Response: {e.response.text}")
    except Exception as e:
        print(f"❌ An unexpected error occurred: {e}")

# --- RUN THE SCRIPT ---
if __name__ == "__main__":
    get_languages()