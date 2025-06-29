from fastapi import APIRouter, Request #type: ignore
from fastapi.responses import StreamingResponse  #type: ignore
import os
import asyncio
import json
from api.v1.rate_limiter import limiter
from police_calls import active_calls

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
def get_current_calls(request: Request):
    calls = active_calls.get_calls()
    return calls