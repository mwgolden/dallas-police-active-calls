from fastapi import APIRouter, Request, Depends, HTTPException, status #type: ignore
from fastapi.responses import StreamingResponse  #type: ignore
import os
import asyncio
import json
from api.v1.rate_limiter import limiter
from police_calls import active_calls
from fastapi.security.api_key import APIKeyHeader


API_KEY_NAME = "X-Api-Key"

api_key_header = APIKeyHeader(name=API_KEY_NAME, auto_error=False)

router = APIRouter()

event_queue = asyncio.Queue()

async def verify_api_key(api_key: str = Depends(api_key_header)):
    if api_key != os.getenv("EVENT_PUBLISH_API_KEY"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing api key"
        )

async def event_publisher():
    while True:
        event = await event_queue.get()
        yield json.dumps(event)
        await asyncio.sleep(0.1)

@router.post("/events/")
async def receive_events(request:Request, api_key: str = Depends(verify_api_key)):
    event = await request.json()
    await event_queue.put(event)
    return {"message": event}

@router.get("/get-events/")
async def get_events():
    return StreamingResponse(event_publisher(), media_type="text/event-stream")

@router.get("/current-calls/")
@limiter.limit("3/second")
async def get_current_calls(request: Request):
    calls = await active_calls.get_calls()
    return calls