import json
import boto3
from datetime import datetime
import pytz
import os

endpoint = os.getenv("DPD_ACTIVE_CALLS_ENDPOINT")
bot = os.getenv("BOT_NAME")
bucket = os.getenv("BUCKET_NAME")
bucket_key = os.getenv("FOLDER")
lambda_to_invoke = os.getenv("LAMBDA_TO_INVOKE")


def lambda_handler(event, context):
    evt = {
        "bot_name": bot,
        "endpoint": endpoint
    }
    lambda_client = boto3.client('lambda')
    response = lambda_client.invoke(
        FunctionName=lambda_to_invoke,
        InvocationType='RequestResponse',
        Payload=json.dumps(evt)
    )
    data = json.load(response['Payload'])
    print(data)
    return {
        "statusCode": 200,
        "body": data
    }