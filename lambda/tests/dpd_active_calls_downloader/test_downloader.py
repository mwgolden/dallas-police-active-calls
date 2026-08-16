import pytest
from unittest.mock import MagicMock
from dpd_active_calls_downloader.app import write_to_s3, lambda_handler

@pytest.fixture
def data():
    return [
        {
            "incident_number": "26-1487409",
            "division": "South Central",
            "nature_of_call": "7X - Major Accident",
            "priority": "2",
            "date": "2026-08-14T00:00:00.000",
            "time": "00:54:06",
            "unit_number": "BLOCK7",
            "location": "CHERRY VALLEY BLVD / S LANCASTER RD",
            "beat": "756",
            "reporting_area": "4375",
            "status": "At Scene"
        }
    ]

@pytest.fixture
def lambda_context():
    context = MagicMock()
    context.function_name = "test-lambda"

    return context


@pytest.fixture
def test_bucket(mock_s3):
    mock_s3.create_bucket(Bucket="test-bucket")

    return "test-bucket"


def test_write_s3_data(mock_s3, test_bucket, data, monkeypatch):

    monkeypatch.setenv("BUCKET_NAME", "test-bucket")
    monkeypatch.setenv("FOLDER", "bucket-key")
    response = write_to_s3(data)
    response_meta = response.get("ResponseMetadata")

    assert response_meta.get("HTTPStatusCode") == 200

    objects = mock_s3.list_objects_v2(
        Bucket="test-bucket",
        Prefix="bucket-key/"
    )

    assert objects["KeyCount"] == 1

def test_lambda_handler(monkeypatch, lambda_context, data, mock_s3, test_bucket):
    mock_http_request = MagicMock(return_value=data)

    monkeypatch.setattr(
        "dpd_active_calls_downloader.app.http_request",
        mock_http_request
    )

    monkeypatch.setenv("BOT_NAME", "police-active-calls")
    monkeypatch.setenv("DPD_ACTIVE_CALLS_ENDPOINT", "https://some-url/xyz.json")
    monkeypatch.setenv("BUCKET_NAME", "test-bucket")
    monkeypatch.setenv("FOLDER", "bucket-key")

    response = lambda_handler(event={}, context=lambda_context)

    assert response["statusCode"] == 200
    mock_http_request.assert_called_once()

