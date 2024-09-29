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

    response = call_table.scan(
        FilterExpression=Attr('change_type').ne('delete')
    )
    calls = response['Items']

    address_cache_response = address_cache.scan()
    
    latest_calls = {}
    addresses = {}

    for address in address_cache_response['Items']:
        addresses[address['address_id']] = address['addresses']

    for call in calls:
        call_id = call['call_id']
        update_date =  datetime.strptime(call['update_date'], '%Y-%m-%d %H:%M:%S')

        if latest_calls.get('call_id') is None or update_date > datetime.strptime(latest_calls[call_id]['update_date'], '%Y-%m-%d %H:%M:%S'):
            call['address'] = addresses.get(call['address_id'])
            latest_calls[call_id] = call
            

    latest_records_list = list(latest_calls.values())
    return {'current_active_calls': latest_records_list}