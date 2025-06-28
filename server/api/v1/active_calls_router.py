from fastapi import APIRouter, Request #type: ignore
from fastapi.responses import StreamingResponse  #type: ignore
import os
import asyncio
import json
from api.v1.rate_limiter import limiter
import httpx

router = APIRouter()

event_queue = asyncio.Queue()

async def event_publisher():
    while True:
        event = await event_queue.get()
        yield json.dumps(event)
        await asyncio.sleep(0.1)

@router.post("/events/")
async def receive_events(request:Request):
    event = await request.json()
    await event_queue.put(event)
    return {"message": event}

@router.get("/get-events/")
async def get_events():
    return StreamingResponse(event_publisher(), media_type="text/event-stream")

@router.get("/current-calls/")
@limiter.limit("3/minute")
async def get_current_calls(request: Request):
    api_key = os.getenv("DPD_ACTIVE_CALLS_API_KEY")
    URL = os.getenv("DPD_CURRENT_CALLS_URL")
    headers = {"X-API-Key": api_key}
    async with httpx.AsyncClient() as client:
        response = await client.get(URL, headers=headers, timeout=None)
        return response.json()