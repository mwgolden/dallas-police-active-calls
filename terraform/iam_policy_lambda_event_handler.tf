data "aws_iam_policy_document" "lambda_policy_event_handler" {
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
      actions = [ 
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [ "${aws_sqs_queue.s3_created_queue_1.arn}" ]
    }

    statement {
      effect = "Allow"
      actions = [ 
        "dynamodb:*"
       ]
       resources = [ "${aws_dynamodb_table.address_cache.arn}", "${aws_dynamodb_table.dpd_active_calls_file_cache.arn}", "${aws_dynamodb_table.dpd_active_calls.arn}" ]
    }
}