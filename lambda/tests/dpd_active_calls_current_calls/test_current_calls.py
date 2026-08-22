import pytest
import json
import boto3
from pathlib import Path


from dpd_active_calls_current_calls.app import lambda_handler, get_current_active_calls


def read_json_file(data_path):
    with open(data_path) as f:
        return json.load(f)

def load_table(table_name, data):

    db_client = boto3.client('dynamodb')

    item = {}
    for record in data["Items"]:
        for key, val in record.items():
            item[key] = convert_to_item(val)
            
        db_client.put_item(
            Item=item,
            TableName=table_name
        )

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


def test_integration_dpd_current_calls(mock_dynamodb, monkeypatch):
    active_calls_path = Path(Path(__file__).resolve().parent.parent / "fixtures" / "test-data" / "active_calls_table.json")
    address_cache_path = Path(Path(__file__).resolve().parent.parent / "fixtures" / "test-data" / "address_cache_table.json")

    active_calls_data = read_json_file(data_path=active_calls_path)
    address_data = read_json_file(data_path=address_cache_path)

    load_table(table_name="dpd_active_calls", data=active_calls_data)
    load_table(table_name="address_cache", data=address_data)

    monkeypatch.setenv("CALL_TABLE", "dpd_active_calls")
    monkeypatch.setenv("ADDRESS_CACHE", "address_cache")
    response = lambda_handler(event={}, context={})
    current_call_data = json.loads(response.get("body", {}))

    expected_call_ids = {
        "3257c5f37e29e5282b69024475b1fdc1dd41e830", 
        "5ad59cc66961e91b62549c7fd1503fcd4cb6f0a1"
    }

    response_call_ids = {item["call_id"] for item in current_call_data.get("current_active_calls", [])}

    assert response_call_ids == expected_call_ids


def test_most_recent_call():
    # Objects reduced to necessary fields
    multiple_same_call_id = [
        {
            "call_id": "3257c5f37e29e5282b69024475b1fdc1dd41e830",
            "change_type": "add",
            "update_date": "2026-08-18 02:46:15",
            "address_id": "66af38cee1b4f0d2ce7393adb0164e47f689646b"
        },
        {
            "call_id": "3257c5f37e29e5282b69024475b1fdc1dd41e830",
            "change_type": "update",
            "update_date": "2026-08-18 03:46:15",
            "address_id": "66af38cee1b4f0d2ce7393adb0164e47f689646b"
        },
        {
            "call_id": "3257c5f37e29e5282b69024475b1fdc1dd41e830",
            "change_type": "update",
            "update_date": "2026-08-18 04:46:15",
            "address_id": "66af38cee1b4f0d2ce7393adb0164e47f689646b"
        }
    ]

    current_calls = get_current_active_calls(calls=multiple_same_call_id, addresses=dict())

    assert len(current_calls) == 1
    assert current_calls[0]["update_date"] == "2026-08-18 04:46:15"


def test_deleted_most_recent_call():
    # Objects reduced to necessary fields
    multiple_same_call_id = [
        {
            "call_id": "3257c5f37e29e5282b69024475b1fdc1dd41e830",
            "change_type": "add",
            "update_date": "2026-08-18 02:46:15",
            "address_id": "66af38cee1b4f0d2ce7393adb0164e47f689646b"
        },
        {
            "call_id": "3257c5f37e29e5282b69024475b1fdc1dd41e830",
            "change_type": "update",
            "update_date": "2026-08-18 03:46:15",
            "address_id": "66af38cee1b4f0d2ce7393adb0164e47f689646b"
        },
        {
            "call_id": "3257c5f37e29e5282b69024475b1fdc1dd41e830",
            "change_type": "delete",
            "update_date": "2026-08-18 04:46:15",
            "address_id": "66af38cee1b4f0d2ce7393adb0164e47f689646b"
        }
    ]

    current_calls = get_current_active_calls(calls=multiple_same_call_id, addresses=dict())

    assert len(current_calls) == 0