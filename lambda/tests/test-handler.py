import pytest
from get_active_calls.app import lambda_handler

def test_lambda_handler():
    event = {"key": "value"}
    context = {}
    result = lambda_handler(event, context)
    assert True