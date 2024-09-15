import boto3
import json
import os
import time
from dynamodb_utils import convert_to_item, put_records


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
    put_records(items, ADDRESS_CACHE_TBL)
                

