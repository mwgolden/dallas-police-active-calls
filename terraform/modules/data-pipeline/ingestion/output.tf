output "sns_create_topic_arn" {
    value = aws_sns_topic.s3_create_object_topic.arn
}