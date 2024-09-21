resource "aws_sns_topic" "s3_create_object_topic" {
    name = "s3-create-object-topic"
}

data "aws_iam_policy_document" "sns_topic_policy" {
    statement {
        effect = "Allow"

        principals {
            type = "*"
            identifiers = [ "*" ]
        }
        actions = ["sns:Publish"]
        resources = [ aws_sns_topic.s3_create_object_topic.arn ]
        condition {
            test = "ArnEquals"
            variable = "aws:SourceArn"
            values = [ aws_s3_bucket.police_data.arn ]
        }
    }
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
    arn = aws_sns_topic.s3_create_object_topic.arn
    policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_s3_bucket_notification" "create_object_notification" {
    bucket = aws_s3_bucket.police_data.id
    topic {
        topic_arn = aws_sns_topic.s3_create_object_topic.arn
        events = ["s3:ObjectCreated:*"]
        filter_prefix = "raw/"
        filter_suffix = ".json"
    }
}

resource "aws_sns_topic_subscription" "download_event_subscription_1" {
    topic_arn = aws_sns_topic.s3_create_object_topic.arn
    protocol = "sqs"
    endpoint = aws_sqs_queue.s3_created_queue_1.arn
}

resource "aws_sns_topic_subscription" "download_event_subscription_2" {
    topic_arn = aws_sns_topic.s3_create_object_topic.arn
    protocol = "sqs"
    endpoint = aws_sqs_queue.s3_created_queue_2.arn
}