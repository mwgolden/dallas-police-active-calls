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
            values = [ var.police_data_bucket_arn ]
        }
    }
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
    arn = aws_sns_topic.s3_create_object_topic.arn
    policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_s3_bucket_notification" "create_object_notification" {
    bucket = var.police_data_bucket_id
    topic {
        topic_arn = aws_sns_topic.s3_create_object_topic.arn
        events = ["s3:ObjectCreated:*"]
        filter_prefix = "raw/"
        filter_suffix = ".json"
    }
}