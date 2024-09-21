
resource "aws_sqs_queue" "s3_created_queue_1" {
    name = "dpd-active-calls-raw-file-created-queue"
    max_message_size = 2048
    message_retention_seconds = 60
    visibility_timeout_seconds = 90
    #policy = data.aws_iam_policy_document.sqs_policy.json 
}

resource "aws_sqs_queue_policy" "s3_created_queue_1_policy" {
  queue_url = aws_sqs_queue.s3_created_queue_1.id
  policy = data.aws_iam_policy_document.sqs_policy.json
}

resource "aws_sqs_queue" "s3_created_queue_2" {
    name = "dpd-active-calls-address-processing-queue"
    max_message_size = 2048
    message_retention_seconds = 60
    visibility_timeout_seconds = 90
   #policy = data.aws_iam_policy_document.sqs_policy.json 
}

resource "aws_sqs_queue_policy" "s3_created_queue_2_policy" {
  queue_url = aws_sqs_queue.s3_created_queue_2.id
  policy = data.aws_iam_policy_document.sqs_policy.json
}

resource "aws_sqs_queue" "geocode_address_processing_queue" {
    name = "dpd-active-calls-geocode-address-queue"
    max_message_size = 60000
    message_retention_seconds = 60
    visibility_timeout_seconds = 90
}

resource "aws_lambda_event_source_mapping" "object_created_event_mapping_1" {
  event_source_arn = aws_sqs_queue.s3_created_queue_1.arn
  function_name    = aws_lambda_function.dpd_active_calls_download_event_handler_lambda.arn
}

resource "aws_lambda_event_source_mapping" "object_created_event_mapping_2" {
  event_source_arn = aws_sqs_queue.s3_created_queue_2.arn
  function_name    = aws_lambda_function.dpd_active_calls_download_event_handler_address_lambda.arn
}


resource "aws_lambda_event_source_mapping" "geocode_address_queued_event" {
  event_source_arn = aws_sqs_queue.geocode_address_processing_queue.arn
  function_name = aws_lambda_function.dpd_forward_geocoder_lambda.arn
}