import boto3
import os
import json
from utils import read_file, transform_address, enqueue
import logging

logger = logging.getLogger()
if not logger.handlers:  # To ensure no duplicate handlers
    logging.basicConfig(level=logging.INFO)
logger.setLevel(logging.INFO)

ADDRESS_QUEUE_URL = os.getenv('ADDRESS_QUEUE_URL')
ADDRESS_CACHE_TBL = os.getenv('ADDRESS_CACHE_TABLE')

def unique_addresses(data):
    logger.info("Get unique addresses from list of addresses")
    addresses = [transform_address(record) for record in data]
    unique_addresses = []
    for address in addresses:
        if address not in unique_addresses:
            unique_addresses = unique_addresses + [address]
    return unique_addresses

def query_address_cache(unique_locations):
    logger.info("Checking address cache")
    try:
        db = boto3.resource('dynamodb')
        address_cache = db.Table(ADDRESS_CACHE_TBL)
        batch_keys = {
            address_cache.name: {
                'Keys': [{'address_id': loc['address_id']} for loc in unique_locations]
            }
        }
        response = db.batch_get_item(RequestItems=batch_keys)
        logger.info("Query for address cache returned successfully")
        return response
    except Exception as e:
        logger.error(f"Error occurred parsing record in lambda event: {str(e)}", exc_info=True)
        raise


def lambda_handler(event, context):
    logger.info(f"Request ID: {context.aws_request_id}, Function Name: {context.function_name}")
    logger.info(f"Event: {event}")
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
        for e in events:
            bucket = e['s3']['bucket']['name']
            key = e['s3']['object']['key']
            cur_file = (bucket, key)
            cur_data = read_file(cur_file)['body']
            addresses = [transform_address(record) for record in cur_data]
            unique_addr = unique_addresses(addresses)
            query_results = query_address_cache(unique_addr)
            result = set([address['address_id'] for address in query_results['Responses']['address_cache']])
            new_addresses = [addr for addr in unique_addr if addr['address_id'] not in result]
            logger.info(f"New address count: {len(new_addresses)}")
            if len(new_addresses) > 0:
                enqueue(new_addresses, ADDRESS_QUEUE_URL)
            logger.info(f"Sent {len(new_addresses)} address records to {ADDRESS_QUEUE_URL}")
    except Exception as e:
        logger.error(f"Error occurred processing address records: {str(e)}", exc_info=True)
        raise