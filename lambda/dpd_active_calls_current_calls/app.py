import os
import boto3
import json
from datetime import datetime
from decimal import Decimal

def serialize_decimal(obj):
    if isinstance(obj, Decimal):
        return str(obj)
    raise TypeError('Type not serializable')

def get_current_active_calls(calls: list, addresses: dict) -> list:
    if not calls:
        return []

    # Find most recent record for each call_id
    current_records = dict()
    for call in calls:
        call_id = call['call_id']
        cur = current_records.get(call_id)
        if not cur or cur['update_date'] < call['update_date']:
            current_call = {
                **call,
                "address": addresses.get(call['address_id'])
            }   
            current_records[call_id] = current_call

    # Filter current_records for active calls
    active_calls = [call for _, call in current_records.items() if call["change_type"] != "delete"]
    
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
