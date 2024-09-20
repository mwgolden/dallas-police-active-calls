import boto3
import json
from hashlib import sha1
from io import BytesIO


def read_file(file: tuple):
    s3 = boto3.client('s3')
    response = s3.get_object(Bucket=file[0], Key=file[1])
    body = response['Body'].read()
    if not body:
        print('The file is empty')
        return None
    else:
        content = body.decode('utf8')
        try:
            json_data = json.loads(content)
            return json_data
        except json.JSONDecodeError as e:
            print(f'failed to parse json: {e}')  
    
def to_flat_file(data, headers):
    file = "|".join(headers) + '\n'
    for item in data:
        row = []
        for header in headers:
            row = row + [item.get(header) if item.get(header) is not None else "" ]
        file = file + "|".join(row) + '\n'
    byte_array = BytesIO(file.encode('utf-8'))
    return byte_array

def save_to_bucket(file, path):
    s3 = boto3.client("s3")
    response = s3.put_object(Bucket=path[0], Key=path[1], Body=file)
    return response

def transform_address(record):
    def get_address_id(address_record):
        address_string = '|'.join(address_record.values())
        return sha1(address_string.encode(encoding='utf-8')).hexdigest()
    address = {}
    block = record.get('block')
    location = record.get('location')
    if block:
        address['address_type'] = 'exact'
    else:
        address['address_type'] = 'intersection'
    address['block'] = '' if block is None else block.lower()
    address['location'] = ",".join([val.strip().lower() for val in location.split('/')])
    address['city'] = 'dallas'
    address['state'] = 'tx'
    address['address_id'] = get_address_id(address)
    return address

def enqueue(record, queue):
    sqs_client = boto3.client('sqs')
    response = sqs_client.send_message(
        QueueUrl=queue,
        MessageBody=json.dumps(record)
    )
    print(response)