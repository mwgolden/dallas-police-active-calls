locals {
  lambda_prefix = "/aws/lambda/"
}

resource "aws_cloudwatch_log_group" "dpd_active_calls_downloader" {
    name = "${local.lambda_prefix}${aws_lambda_function.dpd_active_calls_downloader_lambda.function_name}"
    retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "dpd_active_calls_download_event_handler" {
    name = "${local.lambda_prefix}${aws_lambda_function.dpd_active_calls_download_event_handler_lambda.function_name}"
    retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "dpd_active_calls_download_event_handler_address" {
    name = "${local.lambda_prefix}${aws_lambda_function.dpd_active_calls_download_event_handler_address_lambda.function_name}"
    retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "dpd_active_calls_forward_geocoder" {
    name = "${local.lambda_prefix}${aws_lambda_function.dpd_forward_geocoder_lambda.function_name}"
    retention_in_days = 1
}