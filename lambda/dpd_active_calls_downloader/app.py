import json
import boto3
from datetime import datetime
import pytz
import os
import logging

logger = logging.getLogger()
if not logger.handlers:  # To ensure no duplicate handlers
    logging.basicConfig(level=logging.INFO)
logger.setLevel(logging.INFO)

endpoint = os.getenv("DPD_ACTIVE_CALLS_ENDPOINT")
bot = os.getenv("BOT_NAME")
bucket = os.getenv("BUCKET_NAME")
bucket_key = os.getenv("FOLDER")
lambda_to_invoke = os.getenv("LAMBDA_TO_INVOKE")

def write_to_s3(data):
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
    logger.info(f"Request ID: {context.aws_request_id}, Function Name: {context.function_name}")
    logger.info(f"Bot Name: {bot}, Endpoint: {endpoint}")
    evt = {
        "bot_name": bot,
        "endpoint": endpoint
    }
    try:
        lambda_client = boto3.client('lambda')
        response = lambda_client.invoke(
            FunctionName=lambda_to_invoke,
            InvocationType='RequestResponse',
            Payload=json.dumps(evt)
        )
        logger.info(f"Lambda {lambda_to_invoke} invoked successfully. Response: {response['StatusCode']}")
        data = json.load(response['Payload'])
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
    