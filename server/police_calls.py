import os
import httpx
import asyncio

class PoliceCurrentCalls: 
    def __init__(self):
        self.current_calls = dict()
        self._lock = asyncio.Lock()
    
    async def cache_calls(self):
        api_key = os.getenv("DPD_ACTIVE_CALLS_API_KEY")
        URL = os.getenv("DPD_CURRENT_CALLS_URL")
        headers = {"X-API-Key": api_key}
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(URL, headers=headers, timeout=None)
                data = response.json()
                async with self._lock:
                    self.current_calls = data
        except Exception as e:
            print(f"Error updating call cache: {e}")

    async def get_calls(self):
        async with self._lock:
            return self.current_calls
 
active_calls = PoliceCurrentCalls()
