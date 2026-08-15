import json
import boto3
from datetime import datetime
import pytz
import os
import logging

from urllib3.poolmanager import PoolManager
from api_token_cache.http_requests import http_request
from api_token_cache.models import DynamoDbConfig

logger = logging.getLogger()
if not logger.handlers:  # To ensure no duplicate handlers
    logging.basicConfig(level=logging.INFO)
logger.setLevel(logging.INFO)

def write_to_s3(data):
    bucket = os.getenv("BUCKET_NAME")
    bucket_key = os.getenv("FOLDER")
    try:
        tz = pytz.timezone('US/Central')
        now = datetime.now(tz)
        s3 = boto3.resource('s3')
        file_name = f"dpd_active_calls_{now.strftime('%Y%m%d%H%M')}.json"
        key = f"{bucket_key}/{file_name}"
        obj = s3.Object(bucket, key)
        response = obj.put(Body=json.dumps(data))
        logger.info(f"{file_name} successfully written to s3://{bucket}/{key}")
        return response
    except Exception as e:
        logger.error(f"Error occurred writing data to s3: {str(e)}", exc_info=True)
        raise

def lambda_handler(event, context):
    bot_name = os.getenv("BOT_NAME")
    endpoint = os.getenv("DPD_ACTIVE_CALLS_ENDPOINT")
    logger.info(f"Request ID: {context.aws_request_id}, Function Name: {context.function_name}")
    logger.info(f"Bot Name: {bot_name}, Endpoint: {endpoint}")
    logger.info(f"API Config Table: {os.getenv("API_CONFIG_TABLE")}")
    logger.info(f"API Toke Cache Table: {os.getenv("API_TOKEN_CACHE_TABLE")}")

    db_config = DynamoDbConfig(
        api_config_table=os.getenv("API_CONFIG_TABLE"),
        api_token_cache_table=os.getenv("API_TOKEN_CACHE_TABLE")
    )
    http_pool = PoolManager()
    try:
        data = http_request(
            url=endpoint,
            bot_name=bot_name,
            db_config=db_config,
            http=http_pool
        )
        write_to_s3(data)

        return {
            "statusCode": 200,
            "body": data
         }
    except Exception as e:
        logger.error(f"Error occurred in function {context.function_name}: {str(e)}", exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
         }