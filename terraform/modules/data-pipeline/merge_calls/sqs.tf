resource "aws_sqs_queue" "merge_calls_queue" {
    name = "dpd-active-calls-raw-file-created-queue"
    max_message_size = 2048
    message_retention_seconds = 60
    visibility_timeout_seconds = 90
}

resource "aws_sqs_queue_policy" "merge_calls_queue_policy" {
  queue_url = aws_sqs_queue.merge_calls_queue.id
  policy = data.aws_iam_policy_document.sqs_policy.json
}

resource "aws_lambda_event_source_mapping" "merge_calls_event_mapping" {
  event_source_arn = aws_sqs_queue.merge_calls_queue.arn
  function_name    = aws_lambda_function.dpd_active_calls_download_event_handler_lambda.arn
}