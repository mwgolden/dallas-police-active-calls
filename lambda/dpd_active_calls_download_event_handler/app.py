import json
import functools
import boto3
from io import BytesIO


def get_records(event_object: dict) -> list:
    event_records = [json.loads(record.get('body')).get('Records') for record in event_object.get('Records')]
    return functools.reduce(lambda a, b: a + b, event_records)

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

def save_to_bucket(file, path):
    s3 = boto3.client("s3")
    response = s3.put_object(Bucket=path[0], Key=path[1], Body=file)
    return response

def to_flat_file(json_data):
    download_date = json_data['as_of']
    body = json_data['body']
    headers = list(body[0].keys()) + ['download_date']
    file = "|".join(headers) + '\n'
    for item in body:
        row = list(item.values()) + [download_date]
        file = file + "|".join(row) + '\n'
    byte_array = BytesIO(file.encode('utf-8'))
    return byte_array

def lambda_handler(event, context):
    events = get_records(event)
    for e in events:
        file = (e['s3']['bucket']['name'], e['s3']['object']['key'])
        json_data = read_file(file)
        flat_file = to_flat_file(json_data)
        flat_file_path = (file[0], file[1].replace('raw', 'stage').replace('json', 'psv'))
        save_to_bucket(flat_file, flat_file_path)



