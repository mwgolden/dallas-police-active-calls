import boto3
import json
import os

ADDRESS_CACHE_TBL = os.getenv('ADDRESS_CACHE_TABLE')
RADAR = os.getenv('RADAR_ENDPOINT')
LAMBDA_QUERY_REST_API = os.getenv('LAMBDA_TO_INVOKE')

def query_radar(query_string):
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


def check_address_cache(address_id):
    db = boto3.resource('dynamodb')
    cache = db.Table(ADDRESS_CACHE_TBL)
    response = cache.get_item(Key = {'address_id': address_id})
    return response.get('Item')

def put_record(item):
    db_client = boto3.client('dynamodb')    
    response = db_client.put_item(
        Item=item,
        TableName=ADDRESS_CACHE_TBL
    )

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
    for record in event['Records']:
        body = json.loads(record['body'])
        address_id = body['address_id']
        if not check_address_cache(address_id=address_id):
            query = ''
            if body['address_type'] == 'exact':
                query = f"?query=${body['city']}+${body['state']}+${body['block']}+${body['location']}"
            else:
                query = f"?query=${body['city']}+${body['state']}+${body['location'].replace(',', ' and ')}"
            addresses = query_radar(query_string=query)
            item = {
                'address_id': {'S': address_id},
                'addresses': convert_to_item(addresses)
            }
            print(item)
            put_record(item)
                

