import json
import functools
import boto3
import os
import time
from io import BytesIO
from hashlib import sha1

QUEUE_URL = os.getenv('ADDRESS_QUEUE_URL')
ADDRESS_CACHE_TBL = os.getenv('ADDRESS_CACHE_TABLE')
DPD_ACTIVE_CALLS_TBL = os.getenv('DPD_ACTIVE_CALLS_TABLE')
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

def put_record(record):
    db_client = boto3.client('dynamodb')
    item = {}
    for key, val in record.items():
        item[key] = convert_to_item(val)
    
    response = db_client.put_item(
        Item=item,
        TableName=DPD_ACTIVE_CALLS_TBL
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

def enqueue(address_record):
    sqs_client = boto3.client('sqs')
    response = sqs_client.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps(address_record)
    )
    print(response)

def update_addresses(json_data, update_date):
    for record in json_data:
        address_dict = transform_address(record)
        id = address_dict['address_id']
        record['address_id'] = id
        record['update_dt'] = update_date
        record['call_id'] = '|'.join([record['incident_number'], record['unit_number']])
        record['expires_on'] = int(time.time()) + TTL_SECONDS
        if not check_address_cache(address_id = id):
            enqueue(address_dict)
        put_record(record=record)

def last_two_files(bucket, prefix):
    s3 = boto3.client('s3')
    s3_objects = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)
    result = s3_objects['Contents']
    while s3_objects.get('NextContinuationToken'):
        token = s3_objects['NextContinuationToken']
        s3_objects = s3.list_objects_v2(Bucket=bucket, Prefix=prefix, ContinuationToken=token)
        result = result + s3_objects['Contents']
    sorted_results = sorted(result, key=lambda o: o['LastModified'])
    sorted_results = [result for result in sorted_results if result['Size'] > 0]
    last_two = sorted_results[-2:]
    for file in last_two:
        file['body'] = read_file((bucket, file['Key']))['body']
    return last_two

def columns_are_same(key, cur_file, prev_file):
    incident_number = key[0]
    unit_number = key[1]
    cur_row = []
    prev_row = []
    for f in cur_file['body']:
        if f['incident_number'] == incident_number and f['unit_number'] == unit_number:
            cur_row = list(f.values())

    for f in prev_file['body']:
        if f['incident_number'] == incident_number and f['unit_number'] == unit_number:
            prev_row = list(f.values()) 
            
    cur_hash = sha1('|'.join(cur_row).encode(encoding='utf-8')).hexdigest()
    prev_hash = sha1('|'.join(prev_row).encode(encoding='utf-8')).hexdigest()
    return cur_hash == prev_hash

def compare_files(cur_file, prev_file):
    cur = set([(item['incident_number'], item['unit_number']) for item in cur_file['body']])
    prev = set([(item['incident_number'], item['unit_number']) for item in prev_file['body']])
    to_delete = prev - cur
    to_add = cur - prev
    to_update = set([item for item in cur & prev if not columns_are_same(item, cur_file, prev_file)])
    return {
        'to_delete': to_delete,
        'to_add': to_add,
        'to_update': to_update
    }


def lambda_handler(event, context):
    events = get_records(event)
    for e in events:
        file = (e['s3']['bucket']['name'], e['s3']['object']['key'])
        json_data = read_file(file)
        download_date = json_data['as_of']
        records = json_data['body']
        update_addresses(records, download_date)

        for file in files:
     ...:     tuples = set()
     ...:     for item in file['body']:
     ...:         tuples.add(tuple([item['incident_number'], item['unit_number']]))
     ...:     file['tuples'] = tuples


        



