import json
import os
import time
from hashlib import sha1
from datetime import datetime
from utils import read_file, transform_address
from dynamodb_utils import convert_to_item, put_records, put_record, get_record
import logging

logger = logging.getLogger()
if not logger.handlers:  # To ensure no duplicate handlers
    logging.basicConfig(level=logging.INFO)
logger.setLevel(logging.INFO)

ACTIVE_CALLS_TABLE = os.getenv('ACTIVE_CALLS_TABLE')
FILE_CACHE = os.getenv('FILE_CACHE')
TTL_SECONDS = int(os.getenv('TTL_SECONDS')) 


def records_are_equal(cur, prev):
    cur_row = [str(cur[key]).lower() for key in cur.keys() if key != 'download_date']
    prev_row = [str(prev[key]).lower() for key in prev.keys() if key != 'download_date']
    cur_hash = sha1('|'.join(cur_row).encode(encoding='utf-8')).hexdigest()
    prev_hash = sha1('|'.join(prev_row).encode(encoding='utf-8')).hexdigest()
    return cur_hash == prev_hash

def compare_files(cur_data, prev_data = None):
    logger.info("Comparing current and previous file data for adds, deletes and updates")
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
    logger.info(f"get data for file: {str(file)}")
    if not file:
        return None
    data = read_file(file)
    body = data['body']
    return_obj = {}
    for item in body:
        id = (item['incident_number'], item['unit_number'])
        return_obj[id] = item 
    return return_obj



def persist_changes(changes):
    logger.info("Persist changes to database")
    try:
        records = []
        for k in changes.keys():
            records = records + changes[k]
        items = []
        update_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        for record in records:
            concat_id_cols = record['incident_number'] + '|' + record['unit_number']
            record['call_id'] = sha1(concat_id_cols.encode(encoding='utf-8')).hexdigest()
            record['update_date'] = update_date
            record['address_id'] = transform_address(record)['address_id']
            record['expires_on'] = int(time.time()) + TTL_SECONDS
            item = {}
            for key, val in record.items():
                item[key] = convert_to_item(val)
            items = items + [item]
        put_records(items, ACTIVE_CALLS_TABLE)
    except Exception as e:
        logger.error(f"Error occurred persisting updates to the database: {str(e)}", exc_info=True)
        raise


def lambda_handler(event, context):
    """
        The download event handler processes file download events.  
        1. Compares current and previous files for add, updates, and deletes
        2. Checks an address cache to verify if the location has been geocoded
        3. Persist changes to dynamodb
    """
    logger.info(f"Request ID: {context.aws_request_id}, Function Name: {context.function_name}")
    print(event)
    events = []
    try:
        for record in event['Records']:
            event_body = json.loads(record['body'])
            message = json.loads(event_body['Message'])
            events.extend(message['Records'])
    except Exception as e:
        logger.error(f"Error occurred parsing record in lambda event: {str(e)}", exc_info=True)
        raise
    try: 
        logger.info(f"There are {len(events)} to process")
        for e in events:
            bucket = e['s3']['bucket']['name']
            key = e['s3']['object']['key']
            cached_file = get_record(FILE_CACHE, {'s3_bucket': bucket})
            cur_file = (bucket, key)
            prev_file = (cached_file['s3_bucket'], cached_file['key']) if cached_file else None
            if prev_file:
                logger.info(f"Compare files -> Current: {bucket}/{key}, Previous: {cached_file['s3_bucket']}/{cached_file['key']}")
            else:
                logger.info(f"Current file: {bucket}/{key}. There is no previous file for comparison")
            cur_data = get_file_body(cur_file)
            prev_data = get_file_body(prev_file)
            changes = compare_files(cur_data, prev_data)
            logger.info([f'{key}: {len(changes[key])}'for key in changes.keys()])
            persist_changes(changes)
            logger.info("Successfully persisted changes to database")
            put_record({'s3_bucket': bucket, 'key': key}, FILE_CACHE)
            logger.info(f"Cache file updated: {bucket}/{key}")
    except Exception as e:
        logger.error(f"Error occurred comparing current and previos files: {str(e)}", exc_info=True)
        raise