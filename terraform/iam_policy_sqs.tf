data "aws_iam_policy_document" "sqs_policy" {
    statement {
      effect = "Allow"
      
      principals {
        type = "*"
        identifiers = [ "*" ]
      }
      actions = ["sqs:SendMessage"]
      resources = [ "arn:aws:sqs:*:*:dpd-active-calls-raw-file-created-queue" ]
      condition {
        test = "ArnEquals"
        variable = "aws:SourceArn"
        values = [aws_s3_bucket.police_data.arn]
      }
    }
}