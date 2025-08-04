resource "aws_sns_topic_subscription" "download_event_subscription" {
    topic_arn = var.s3_create_object_topic_arn
    protocol = "sqs"
    endpoint = aws_sqs_queue.merge_calls_queue.arn
}