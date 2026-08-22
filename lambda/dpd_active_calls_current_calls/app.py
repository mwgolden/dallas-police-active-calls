import os
import boto3
import json
from datetime import datetime
from decimal import Decimal

def serialize_decimal(obj):
    if isinstance(obj, Decimal):
        return str(obj)
    raise TypeError('Type not serializable')

def get_current_active_calls(calls, addresses) -> list:
    if not calls:
        return []

    # Find most recent update_date for each call_id
    current_records = dict()
    for item in calls:
        call_id = item['call_id']
        update_date = datetime.strptime(item['update_date'], "%Y-%m-%d %H:%M:%S")
        change_type = item['change_type']
        cur = current_records.get(call_id)
        if not cur or cur['update_date'] < update_date:
            current_records[call_id] = {"update_date": update_date, "change_type": change_type}
    
    # Filter current_records for active calls and add address record
    active_calls = []
    for call in calls:
        call_id, update_date = call["call_id"], datetime.strptime(call["update_date"], "%Y-%m-%d %H:%M:%S")
        cur = current_records.get(call_id)
        if cur and cur["update_date"] == update_date and cur["change_type"] != "delete":
            call['address'] = addresses.get(call['address_id'])
            active_calls.append(call)

    return active_calls


def lambda_handler(event, context): 
    ddb = boto3.resource('dynamodb')
    call_table = ddb.Table(os.getenv('CALL_TABLE'))
    address_cache = ddb.Table(os.getenv('ADDRESS_CACHE'))

    # Get calls and addresses
    response = call_table.scan()
    address_cache_response = address_cache.scan()

    call_items = response.get("Items", [])
    address_items = address_cache_response.get("Items", [])

    # get cached address data 
    addresses = dict()
    for address in address_items:
        addresses[address['address_id']] = address['addresses']

    active_calls = get_current_active_calls(calls=call_items, addresses=addresses)
    

    return {
        "statusCode": 200,
        "body": json.dumps({'current_active_calls': active_calls}, default=serialize_decimal)
    }
