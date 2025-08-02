resource "aws_cloudwatch_log_group" "dpd_active_calls_downloader" {
    name = "${local.lambda_prefix}${aws_lambda_function.dpd_active_calls_downloader_lambda.function_name}"
    retention_in_days = 1
}
