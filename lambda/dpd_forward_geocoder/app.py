import boto3
import json
import os
import time
from dynamodb_utils import convert_to_item, put_records
import logging

logger = logging.getLogger()
if not logger.handlers:  # To ensure no duplicate handlers
    logging.basicConfig(level=logging.INFO)
logger.setLevel(logging.INFO)


ADDRESS_CACHE_TBL = os.getenv('ADDRESS_CACHE_TABLE')
RADAR = os.getenv('RADAR_ENDPOINT')
LAMBDA_QUERY_REST_API = os.getenv('LAMBDA_TO_INVOKE')
TTL_SECONDS = int(os.getenv('TTL_SECONDS')) 

def query_radar(query_string):
    logger.info("Query Radar api for forward geocoding")
    logger.info(f"URL: {RADAR + query_string}")
    try:
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
    except Exception as e:
        logger.error(f"Error querying api: {str(e)}", exc_info=True)
        raise

def lambda_handler(event, context):
    logger.info(f"Request ID: {context.aws_request_id}, Function Name: {context.function_name}")
    print(event)
    body = []
    try:
        for record in event['Records']:
            if isinstance(body, list):
                body = body + json.loads(record['body'])
            else:
                body = body + [json.loads(record['body'])]
    except Exception as e:
        logger.error(f"Error occurred parsing record in lambda event: {str(e)}", exc_info=True)
        raise
    try:
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
            logger.info(f"Address Item: {addr_item}")
            items.append(addr_item)
            time.sleep(0.1) # ensure only 10 api requests per second
        logger.info(f"Persisting {len(items)} to the database")
        put_records(items, ADDRESS_CACHE_TBL)
        logger.info(f"Successfully appended {len(items)} to the database")
    except Exception as e:
        logger.error(f"Error occurred forward geocoding address data: {str(e)}", exc_info=True)
        raise
                

