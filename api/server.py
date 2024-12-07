from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import boto3
import asyncio
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime

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

@app.get("/current-calls/")
async def get_current_calls():
    ddb = boto3.resource('dynamodb')
    call_table = ddb.Table('dpd_active_calls')
    address_cache = ddb.Table('address_cache')

    # Get calls and addresses
    response = call_table.scan()
    address_cache_response = address_cache.scan()

    # get cached address data 
    addresses = {}
    for address in address_cache_response['Items']:
        addresses[address['address_id']] = address['addresses']

    # Find most recent update_date for each call_id
    current_records = dict()
    for item in response['Items']:
        call_id = item['call_id']
        update_date = datetime.strptime(item['update_date'], "%Y-%m-%d %H:%M:%S")
        change_type = item['change_type']
        cur = current_records.get(call_id)
        if not cur or cur['update_date'] < update_date:
            current_records[call_id] = {"update_date": update_date, "change_type": change_type}

    # Filter current_records for active calls and add address record
    active_calls = []
    for item in response["Items"]:
        call_id, update_date = item["call_id"], datetime.strptime(item["update_date"], "%Y-%m-%d %H:%M:%S")
        cur = current_records.get(call_id)
        if cur and cur["update_date"] == update_date and cur["change_type"] != "delete":
            item['address'] = addresses.get(item['address_id'])
            active_calls.append(item)

    return {'current_active_calls': active_calls}