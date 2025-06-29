import os
import httpx

class PoliceCurrentCalls: 
    def __init__(self):
        self.current_calls = dict()
    
    async def cache_calls(self):
        api_key = os.getenv("DPD_ACTIVE_CALLS_API_KEY")
        URL = os.getenv("DPD_CURRENT_CALLS_URL")
        headers = {"X-API-Key": api_key}
        async with httpx.AsyncClient() as client:
            response = await client.get(URL, headers=headers, timeout=None)
            self.current_calls = response.json()

    def get_calls(self):
        return self.current_calls
 
active_calls = PoliceCurrentCalls()
