import os
import logging
import pytz
import boto3
from datetime import datetime
from utils import to_byte_array, save_to_bucket
from dynamodb_utils import convert_from_item

logger = logging.getLogger()
if not logger.handlers:  # To ensure no duplicate handlers
    logging.basicConfig(level=logging.INFO)
logger.setLevel(logging.INFO)

bucket = os.getenv("BUCKET_NAME")
bucket_key = os.getenv("FOLDER")

def write_to_s3(bytes):
    try:
        tz = pytz.timezone('US/Central')
        now = datetime.now(tz)
        s3_client = boto3.client('s3')
        file_name = f"dpd_active_calls_{now.strftime('%Y%m%d%H%M%S%f')[:-3]}.psv"
        key = f"{bucket_key}/{file_name}"
        response = s3_client.put_object(Bucket=bucket, Key=key, Body=bytes)
        logger.info(f"{file_name} successfully written to s3://{bucket}/{key}")
        return response
    except Exception as e:
        logger.error(f"Error occurred writing data to s3: {str(e)}", exc_info=True)
        raise

def lambda_handler(event, context):
    logger.info(event)
    records = [record['dynamodb']['NewImage'] for record in event['Records'] if record['eventName'] == 'INSERT']
    from_items = convert_from_item(records)
    headers = ['call_id','update_date', 'address_id', 'beat', 'block', 'change_type', 'date', 'division', 'expires_on', 'incident_number', 'location', 'nature_of_call', 'priority', 'reporting_area', 'status', 'time', 'unit_number']
    file = to_byte_array(from_items, headers)
    write_to_s3(file)