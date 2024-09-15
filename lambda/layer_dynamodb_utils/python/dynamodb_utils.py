import boto3
import math

def convert_to_item(record):
    if isinstance(record, str):
        return {'S': record}
    elif isinstance(record, (int, float)):
        return {'N': str(record)}
    elif isinstance(record, list):
        return {'L': [convert_to_item(val) for val in record]}
    elif isinstance(record, dict):
        return {'M': {key: convert_to_item(val) for key, val in record.items()}}
    else:
        raise ValueError(f'Unsupported type: {type(record)}')
    
def put_record(record, table):
    db_client = boto3.client('dynamodb')
    item = {}
    for key, val in record.items():
        item[key] = convert_to_item(val)
    
    response = db_client.put_item(
        Item=item,
        TableName=table
    )


def put_records(items, table):
    db_client = boto3.client('dynamodb')   
    requests = [{'PutRequest': {'Item': item}} for item in items] 
    for i in range(math.ceil(len(requests) / 25)):
        start = i * 25
        end = start + 24
        db_client.batch_write_item(RequestItems={table: requests[start:end]})

