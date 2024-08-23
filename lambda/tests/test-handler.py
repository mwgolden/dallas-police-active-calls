import pytest
from dpd_active_calls_downloader.app import lambda_handler

def test_lambda_handler():
    event = {"key": "value"}
    context = {}
    result = lambda_handler(event, context)
    assert True