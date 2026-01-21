import httpx
import asyncio

API_KEY = "9898502698msh9c488abca06ee0ap17e14ajsnfab6436a89db"
HOST = "judge0-ce.p.rapidapi.com"

async def get_langs():
    url = f"https://{HOST}/languages"
    headers = {
        "X-RapidAPI-Key": API_KEY,
        "X-RapidAPI-Host": HOST
    }

    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        if response.status_code != 200:
            print(f"Error: {response.status_code} - {response.text}")
            return

        langs = response.json()
        print(f" Found {len(langs)} languages.")
        print("-" * 30)

        # Filter for C++
        cpp_langs = [l for l in langs if "C++" in l['name']]
        for l in cpp_langs:
            print(f"ID: {l['id']} | Name: {l['name']}")

if __name__ == "__main__":
    asyncio.run(get_langs())