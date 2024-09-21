data "aws_iam_policy_document" "sqs_policy" {
    statement {
      effect = "Allow"
      
      principals {
        type = "*"
        identifiers = [ "*" ]
      }
      actions = ["sqs:SendMessage"]
      resources = [ aws_sqs_queue.s3_created_queue_1.arn ]
      condition {
        test = "ArnEquals"
        variable = "aws:SourceArn"
        values = [aws_sns_topic.s3_create_object_topic.arn]
      }
    }

    statement {
      effect = "Allow"
      
      principals {
        type = "*"
        identifiers = [ "*" ]
      }
      actions = ["sqs:SendMessage"]
      resources = [ aws_sqs_queue.s3_created_queue_2.arn ]
      condition {
        test = "ArnEquals"
        variable = "aws:SourceArn"
        values = [aws_sns_topic.s3_create_object_topic.arn]
      }
    }
}