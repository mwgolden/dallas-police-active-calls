data "aws_iam_policy_document" "lambda_policy_dynamodb_updates" {
    statement {
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
       ]
       resources = [ 
         "arn:aws:logs:*:*:*"
        ]
    }

    statement {
      effect = "Allow"
      actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:List*"
      ]
      resources = [ "${aws_s3_bucket.police_data.arn}", "${aws_s3_bucket.police_data.arn}/*" ]
    }

    statement {
      effect = "Allow"
      actions = ["lambda:InvokeFunction"]
      resources = [ "${aws_dynamodb_table.dpd_active_calls.arn}" ]
    }

    statement {
      effect = "Allow"
      actions = [ 
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
       ]
       resources = [ "${aws_dynamodb_table.dpd_active_calls.arn}/stream/*" ]
    }
}