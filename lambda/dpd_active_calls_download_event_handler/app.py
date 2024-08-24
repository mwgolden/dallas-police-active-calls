import json
import functools


def get_records(event_object: dict) -> list:
    event_records = [json.loads(record.get('body')).get('Records') for record in event_object.get('Records')]
    print(event_records)
    print(type(event_records[0]))
    return functools.reduce(lambda a, b: a + b, event_records)

def lambda_handler(event, context):
    events = get_records(event)
    for e in events:
        print(json.dumps(e))
