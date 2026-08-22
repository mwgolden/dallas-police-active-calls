import pytest
import boto3
from moto import mock_aws
from api_token_cache.models import DynamoDbConfig


@pytest.fixture
def mock_s3():
    with mock_aws():
        s3 = boto3.client("s3")

        yield s3

@pytest.fixture()
def db_config():
    return {
        "active_calls_table": "dpd_active_calls",
        "address_cache_table": "address_cache"
    }


@pytest.fixture
def mock_dynamodb(db_config):
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")

        table = dynamodb.create_table( # type: ignore
            TableName=db_config["address_cache_table"],
            KeySchema=[
                {"AttributeName": "address_id", "KeyType": "HASH" }
            ],
            AttributeDefinitions=[
                { "AttributeName": "address_id", "AttributeType": "S" }
            ],
            BillingMode="PAY_PER_REQUEST"
        )

        cache_table = dynamodb.create_table(  # type: ignore
             TableName=db_config["active_calls_table"],
             KeySchema=[
                  {"AttributeName": "call_id", "KeyType": "HASH"}
             ],
             AttributeDefinitions=[
                  { "AttributeName": "call_id", "AttributeType": "S" }
             ],
            BillingMode="PAY_PER_REQUEST"
        )

        table.wait_until_exists()
        cache_table.wait_until_exists()
        yield dynamodb

