data "aws_iam_policy_document" "sqs_policy" {
    statement {
      effect = "Allow"
      
      principals {
        type = "*"
        identifiers = [ "*" ]
      }
      actions = ["sqs:SendMessage"]
      resources = [ aws_sqs_queue.merge_calls_queue.arn ]
      condition {
        test = "ArnEquals"
        variable = "aws:SourceArn"
        values = [var.s3_create_object_topic_arn]
      }
    }
}