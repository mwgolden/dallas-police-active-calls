resource "aws_sns_topic_subscription" "download_event_subscription_2" {
    topic_arn = var.s3_create_object_topic_arn
    protocol = "sqs"
    endpoint = aws_sqs_queue.address_processing_queue.arn
}