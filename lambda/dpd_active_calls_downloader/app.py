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

def write_to_s3(data):
    tz = pytz.timezone('US/Central')
    now = datetime.now(tz)
    s3 = boto3.resource('s3')
    file_name = f"dpd_active_calls_{now.strftime('%Y%m%d%H%M')}.json"
    key = f"{bucket_key}/{file_name}"
    obj = s3.Object(bucket, key)
    response = obj.put(Body=json.dumps(data))
    return response


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
    print(response)
    data = json.load(response['Payload'])
    write_to_s3(data)
    return {
        "statusCode": 200,
        "body": data
    }