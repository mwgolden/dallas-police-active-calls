import os
import logging
import pytz
import boto3
import requests
from datetime import datetime
from utils import to_byte_array
from dynamodb_utils import convert_from_item

logger = logging.getLogger()
if not logger.handlers:  # To ensure no duplicate handlers
    logging.basicConfig(level=logging.INFO)
logger.setLevel(logging.INFO)

s3_bucket = os.getenv("BUCKET_NAME")
calls_bucket_key = os.getenv("CALLS_FOLDER")
address_bucket_key = os.getenv("ADDRESS_FOLDER")
event_url = os.getenv("EVENT_URL")

def write_to_s3(bytes, bucket, key):
    try:
        s3_client = boto3.client('s3')
        response = s3_client.put_object(Bucket=bucket, Key=key, Body=bytes)
        logger.info(f"data successfully written to s3://{bucket}/{key}")
        return response
    except Exception as e:
        logger.error(f"Error occurred writing data to s3: {str(e)}", exc_info=True)
        raise

def push_events(items):
    try:
        headers = {'Content-Type': 'application/json', 'Accept':'application/json'}
        logger.info("publish updates to api")
        requests.post(event_url, json=items, headers=headers)
    except Exception as e:
        logger.error(f"Failed to publish events to api: \n {str(e)}")

def lambda_handler(event, context):
    logger.info(event)
    tz = pytz.timezone('US/Central')
    now = datetime.now(tz)
    calls = []
    addresses = []
    for record in event['Records']:
        if record['eventName'] == 'INSERT':
            if 'dpd_active_calls' in record['eventSourceARN']:
                calls.append(record['dynamodb']['NewImage'])
            elif 'address_cache' in record['eventSourceARN']:
                addresses.append(record['dynamodb']['NewImage'])
            else:
                logger.warning(f"No table match for {record['eventSourceARN']}")
    if len(calls) > 0:
        from_items = convert_from_item(calls)
        headers = ['call_id','update_date', 'address_id', 'beat', 'block', 'change_type', 'date', 'division', 'expires_on', 'incident_number', 'location', 'nature_of_call', 'priority', 'reporting_area', 'status', 'time', 'unit_number']
        file = to_byte_array(from_items, headers)
        file_name = f"dpd_active_calls_{now.strftime('%Y%m%d%H%M%S%f')[:-3]}.psv"
        key = f"{calls_bucket_key}/{file_name}"
        write_to_s3(file, s3_bucket, key)
        push_events({'event': 'call_changes', 'data': from_items})
    if len(addresses) > 0:
        from_items = convert_from_item(addresses)
        headers = ['address_id', 'addresses', 'expires_on']
        file = to_byte_array(from_items, headers)
        file_name = f"dpd_address_{now.strftime('%Y%m%d%H%M%S%f')[:-3]}.psv"
        key = f"{address_bucket_key}/{file_name}"
        write_to_s3(file, s3_bucket, key)
        push_events({'event': 'address_changes', 'data': from_items})