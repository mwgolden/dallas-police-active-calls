import json
import functools
import boto3
import os
import time
from io import BytesIO
from hashlib import sha1
from datetime import datetime
from utils import read_file, transform_address
from dynamodb_utils import convert_to_item, put_records

ACTIVE_CALLS_TABLE = os.getenv('ACTIVE_CALLS_TABLE')
FILE_CACHE = os.getenv('FILE_CACHE')
TTL_SECONDS = int(os.getenv('TTL_SECONDS')) 


def get_records(event_object: dict) -> list:
    event_records = [json.loads(record.get('body')).get('Records') for record in event_object.get('Records')]
    return functools.reduce(lambda a, b: a + b, event_records)

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

def records_are_equal(cur, prev):
    cur_row = [str(cur[key]) for key in cur.keys() if key != 'download_date']
    prev_row = [str(prev[key]) for key in prev.keys() if key != 'download_date']
    cur_hash = sha1('|'.join(cur_row).encode(encoding='utf-8')).hexdigest()
    prev_hash = sha1('|'.join(prev_row).encode(encoding='utf-8')).hexdigest()
    return cur_hash == prev_hash

def compare_files(cur_data, prev_data = None):
    def change_type(data, change_type):
        data['change_type'] = change_type
        return data
    
    cur = set(list(cur_data.keys()))
    to_delete = []
    to_add = []
    to_update = []
    if prev_data:
        prev = set(list(prev_data.keys()))
        to_delete = [change_type(prev_data[id], 'delete') for id in prev - cur]
        to_add = [change_type(cur_data[id], 'add') for id in cur - prev]
        to_update = [change_type(cur_data[id], 'update') for id in cur & prev if not records_are_equal(cur_data[id], prev_data[id])]
    else:
        to_add = [change_type(cur_data[id], 'add') for id in cur]
        
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
        id = (item['incident_number'], item['unit_number'])
        return_obj[id] = item 
    return return_obj



def persist_changes(changes):
    records = []
    for k in changes.keys():
        records = records + changes[k]
    items = []
    for record in records:
        concat_id_cols = record['incident_number'] + '|' + record['unit_number']
        record['call_id'] = sha1(concat_id_cols.encode(encoding='utf-8')).hexdigest()
        record['address_id'] = transform_address(record)['address_id']
        record['expires_on'] = int(time.time()) + TTL_SECONDS
        item = {}
        for key, val in record.items():
            item[key] = convert_to_item(val)
        items = items + [item]
    print(items)
    put_records(items, ACTIVE_CALLS_TABLE)


def lambda_handler(event, context):
    """
        The download event handler processes file download events.  
        1. Compares current and previous files for add, updates, and deletes
        2. Checks an address cache to verify if the location has been geocoded
        3. Persist changes to dynamodb
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
        persist_changes(changes)
        update_cache_file(bucket, key)