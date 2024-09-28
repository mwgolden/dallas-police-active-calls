from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import json
import asyncio

app = FastAPI()

event_queue = asyncio.Queue()

async def event_publisher():
    while True:
        event = await event_queue.get()
        yield f"data: {event}\n\n"
        await asyncio.sleep(0.1)

@app.post("/events/")
async def receive_events(request:Request):
    event = await request.json()
    await event_queue.put(event)
    return {"message": event}

@app.get("/get-events/")
async def get_events():
    return StreamingResponse(event_publisher(), media_type="text/event-stream")