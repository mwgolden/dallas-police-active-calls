import json
import functools
import boto3
import os
from io import BytesIO
from hashlib import sha1

QUEUE_URL = os.getenv('ADDRESS_QUEUE_URL')
ADDRESS_CACHE_TBL = os.getenv('ADDRESS_CACHE_TABLE')
DPD_ACTIVE_CALLS_TBL = os.getenv('DPD_ACTIVE_CALLS_TABLE')


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
        item[key] = {'S': val}
    
    response = db_client.put_item(
        Item=item,
        TableName=DPD_ACTIVE_CALLS_TBL
    )

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
        if not check_address_cache(address_id = id):
            enqueue(address_dict)
        put_record(record=record)


def lambda_handler(event, context):
    events = get_records(event)
    for e in events:
        file = (e['s3']['bucket']['name'], e['s3']['object']['key'])
        json_data = read_file(file)
        download_date = json_data['as_of']
        records = json_data['body']
        update_addresses(records, download_date)
        



