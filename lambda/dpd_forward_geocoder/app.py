import boto3
import json
import os
import time
import math

ADDRESS_CACHE_TBL = os.getenv('ADDRESS_CACHE_TABLE')
RADAR = os.getenv('RADAR_ENDPOINT')
LAMBDA_QUERY_REST_API = os.getenv('LAMBDA_TO_INVOKE')
TTL_SECONDS = int(os.getenv('TTL_SECONDS')) 

def query_radar(query_string):
    print(f'URL: {RADAR + query_string}')
    bot = 'radar'
    endpoint = RADAR + query_string
    evt = {
        "bot_name": bot,
        "endpoint": endpoint
    }
    lambda_client = boto3.client('lambda')
    response = lambda_client.invoke(
        FunctionName=LAMBDA_QUERY_REST_API,
        InvocationType='RequestResponse',
        Payload=json.dumps(evt)
    )
    payload = json.load(response['Payload'])
    addresses = payload['body']['addresses']
    return addresses

def put_records(items):
    db_client = boto3.client('dynamodb')   
    requests = [{'PutRequest': {'Item': addr}} for addr in items] 
    for i in range(math.ceil(len(requests) / 25)):
        start = i * 25
        end = start + 24
        db_client.batch_write_item(RequestItems={ADDRESS_CACHE_TBL: requests[start:end]})

def convert_to_item(record):
    if isinstance(record, str):
        return {'S': record}
    elif isinstance(record, (int, float)):
        return {'N': str(record)}
    elif isinstance(record, list):
        return {'L': [convert_to_item(val) for val in record]}
    elif isinstance(record, dict):
        return {'M': {key: convert_to_item(val) for key, val in record.items()}}
    else:
        raise ValueError(f'Unsupported type: {type(record)}')

def lambda_handler(event, context):
    print(event)
    body = []
    for record in event['Records']:
        if isinstance(body, list):
            body = body + json.loads(record['body'])
        else:
            body = body + [json.loads(record['body'])]
    items = []
    for address in body:
        address_id = address['address_id']
        query = ''
        if address['address_type'] == 'exact':
            query = f"?query=${address['city']}+${address['state']}+${address['block']}+${address['location']}"
        else:
            query = f"?query=${address['city']}+${address['state']}+${address['location'].replace(',', ' and ')}"
        addresses = query_radar(query_string=query)
        addr_item = {
            'address_id': {'S': address_id},
            'expires_on': convert_to_item(int(time.time()) + TTL_SECONDS),
            'addresses': convert_to_item(addresses)
        }
        print(addr_item)
        items.append(addr_item)
    put_records(items)
                

