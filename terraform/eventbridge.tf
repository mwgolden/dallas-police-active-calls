
resource "aws_cloudwatch_event_rule" "every_2_minutes" {
  name = "query_dpd_active_calls_every_2_minutes_rule"
  description = "Download Dallas police active calls every two minutes"
  schedule_expression = "rate(2 minutes)"
}

resource "aws_cloudwatch_event_target" "downloader" {
  rule = aws_cloudwatch_event_rule.every_2_minutes.name
  arn = aws_lambda_function.dpd_active_calls_downloader_lambda.arn
}
