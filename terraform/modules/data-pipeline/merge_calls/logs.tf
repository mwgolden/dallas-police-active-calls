locals {
  lambda_prefix = "/aws/lambda/"
}

resource "aws_cloudwatch_log_group" "dpd_active_calls_download_event_handler" {
    name = "${local.lambda_prefix}${aws_lambda_function.dpd_active_calls_download_event_handler_lambda.function_name}"
    retention_in_days = 1
}