import json
import functools
import boto3
import os
import time
from io import BytesIO
from hashlib import sha1
from datetime import datetime

ADDRESS_QUEUE_URL = os.getenv('ADDRESS_QUEUE_URL')
ADDRESS_CACHE_TBL = os.getenv('ADDRESS_CACHE_TABLE')
CHANGE_PROCESS_QUEUE = os.getenv('CHANGE_PROCESS_QUEUE')
FILE_CACHE = os.getenv('FILE_CACHE')
TTL_SECONDS = int(os.getenv('TTL_SECONDS')) 


def get_records(event_object: dict) -> list:
    event_records = [json.loads(record.get('body')).get('Records') for record in event_object.get('Records')]
    return functools.reduce(lambda a, b: a + b, event_records)

def read_file(file: tuple):
    s3 = boto3.client('s3')
    response = s3.get_object(Bucket=file[0], Key=file[1])
    body = response['Body'].read()
    if not body:
        print('The file is empty')
        return None
    else:
        content = body.decode('utf8')
        try:
            json_data = json.loads(content)
            return json_data
        except json.JSONDecodeError as e:
            print(f'failed to parse json: {e}')  

def save_to_bucket(file, path):
    s3 = boto3.client("s3")
    response = s3.put_object(Bucket=path[0], Key=path[1], Body=file)
    return response

def to_flat_file(json_data):
    object_keys = ["incident_number",
            "division",
            "nature_of_call",
            "priority",
            "date",
            "time",
            "unit_number",
            "block",
            "location",
            "beat",
            "reporting_area",
            "status"]
    download_date = json_data['as_of']
    body = json_data['body']
    headers = object_keys + ['download_date']
    file = "|".join(headers) + '\n'
    for item in body:
        row = []
        for header in object_keys:
            row = row + [item.get(header) if item.get(header) is not None else "" ]
        row = row + [download_date]
        file = file + "|".join(row) + '\n'
    byte_array = BytesIO(file.encode('utf-8'))
    return byte_array

def get_address_id(address_record):
    address_string = '|'.join(address_record.values())
    return sha1(address_string.encode(encoding='utf-8')).hexdigest()

def check_address_cache(address_id):
    db = boto3.resource('dynamodb')
    cache = db.Table(ADDRESS_CACHE_TBL)
    response = cache.get_item(Key = {'address_id': address_id})
    return response.get('Item')

def get_cache_file(bucket):
    db = boto3.resource('dynamodb')
    cache = db.Table(FILE_CACHE)
    response = cache.get_item(Key = {'s3_bucket': bucket})
    return response.get('Item')

def update_cache_file(bucket, key):
    db_client = boto3.client('dynamodb')
    item = {
        's3_bucket': {'S': bucket},
        'key': {'S': key}
    }
    response = db_client.put_item(
        Item=item,
        TableName=FILE_CACHE
    )

def put_record(record, table):
    db_client = boto3.client('dynamodb')
    item = {}
    for key, val in record.items():
        item[key] = convert_to_item(val)
    
    response = db_client.put_item(
        Item=item,
        TableName=table
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

def transform_address(record):
    address = {}
    block = record.get('block')
    location = record.get('location')
    if block:
        address['address_type'] = 'exact'
    else:
        address['address_type'] = 'intersection'
    address['block'] = '' if block is None else block.lower()
    address['location'] = ",".join([val.strip().lower() for val in location.split('/')])
    address['city'] = 'dallas'
    address['state'] = 'tx'
    address['address_id'] = get_address_id(address)
    return address

def unique_addresses(data):
    addresses = [transform_address(record) for record in data]
    unique_addresses = []
    for address in addresses:
        if address not in unique_addresses:
            unique_addresses = unique_addresses + [address]
    return unique_addresses

def enqueue(record, queue):
    sqs_client = boto3.client('sqs')
    response = sqs_client.send_message(
        QueueUrl=queue,
        MessageBody=json.dumps(record)
    )
    print(response)

def query_address_cache(unique_locations):
    db = boto3.resource('dynamodb')
    address_cache = db.Table(ADDRESS_CACHE_TBL)
    batch_keys = {
        address_cache.name: {
            'Keys': [{'address_id': loc['address_id']} for loc in unique_locations]
        }
    }
    response = db.batch_get_item(RequestItems=batch_keys)
    return response


def records_are_equal(cur, prev):
    cur_row = [cur[key] for key in cur.keys() if key != 'download_date']
    prev_row = [prev[key] for key in prev.keys() if key != 'download_date']
    cur_hash = sha1('|'.join(cur_row).encode(encoding='utf-8')).hexdigest()
    prev_hash = sha1('|'.join(prev_row).encode(encoding='utf-8')).hexdigest()
    return cur_hash == prev_hash

def compare_files(cur_data, prev_data = None):
    cur = set(list(cur_data.keys()))
    to_delete = []
    to_add = []
    to_update = []
    if prev_data:
        prev = set(list(prev_data.keys()))
        to_delete = [prev_data[id] for id in prev - cur]
        to_add = [cur_data[id] for id in cur - prev]
        to_update = [cur_data[id] for id in cur & prev if not records_are_equal(cur_data[id], prev_data[id])]
    else:
        to_add = [cur_data[id] for id in cur]
        
    return {
        'to_delete': to_delete,
        'to_add': to_add,
        'to_update': to_update
    }

def get_file_body(file: tuple):
    if not file:
        return None
    data = read_file(file)
    body = data['body']
    download_date = data['as_of']
    return_obj = {}
    for item in body:
        item['download_date'] = download_date
        item['address_id'] = transform_address(item)['address_id']
        item['expires_on'] = int(time.time()) + TTL_SECONDS
        id = (item['incident_number'], item['unit_number'])
        return_obj[id] = item 
    return return_obj


def lambda_handler(event, context):
    """
        The download event handler processes file download events.  
        1. Compares current and previous files for add, updates, and deletes
        2. Checks an address cache to verify if the location has been geocoded
        3. enqueues changes for further processing
        4. enqueues new locations for forward geocoding
    """
    events = get_records(event)
    for e in events:
        bucket = e['s3']['bucket']['name']
        key = e['s3']['object']['key']
        cached_file = get_cache_file(bucket)
        cur_file = (bucket, key)
        prev_file = (cached_file['s3_bucket'], cached_file['key']) if cached_file else None
        cur_data = get_file_body(cur_file)
        prev_data = get_file_body(prev_file)
        changes = compare_files(cur_data, prev_data)
        print([f'{key}: {len(changes[key])}'for key in changes.keys()])
        enqueue(changes, CHANGE_PROCESS_QUEUE)
        flatten_cur_data = [cur_data[id] for id in cur_data.keys()]
        addresses = unique_addresses(flatten_cur_data)
        query_results = query_address_cache(addresses)
        result = set([address['address_id'] for address in query_results['Responses']['address_cache']])
        new_addresses = [addr for addr in addresses if addr['address_id'] not in result]
        if len(new_addresses) > 0:
            enqueue(new_addresses, ADDRESS_QUEUE_URL)
        update_cache_file(bucket, key)