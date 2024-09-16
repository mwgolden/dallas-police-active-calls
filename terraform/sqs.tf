
resource "aws_sqs_queue" "s3_created_queue" {
    name = "dpd-active-calls-raw-file-created-queue"
    max_message_size = 2048
    message_retention_seconds = 60
    visibility_timeout_seconds = 90
    policy = data.aws_iam_policy_document.sqs_policy.json 
}

resource "aws_s3_bucket_notification" "create_object_notification" {
    bucket = aws_s3_bucket.police_data.id
    queue {
      queue_arn = aws_sqs_queue.s3_created_queue.arn
      events = ["s3:ObjectCreated:*"]
      filter_suffix = ".json"
    }
}

resource "aws_lambda_event_source_mapping" "object_created_event_mapping" {
  event_source_arn = aws_sqs_queue.s3_created_queue.arn
  function_name    = aws_lambda_function.dpd_active_calls_download_event_handler_lambda.arn
}

resource "aws_sqs_queue" "address_processing_queue" {
    name = "dpd-active-calls-process-address-queue"
    max_message_size = 2048
    message_retention_seconds = 60
    visibility_timeout_seconds = 90
}

resource "aws_lambda_event_source_mapping" "address_queued_event" {
  event_source_arn = aws_sqs_queue.address_processing_queue.arn
  function_name = aws_lambda_function.dpd_forward_geocoder_lambda.arn
}

resource "aws_sqs_queue" "change_processing_queue" {
    name = "dpd-active-calls-process-changes-queue"
    max_message_size = 60000
    message_retention_seconds = 60
    visibility_timeout_seconds = 90
}