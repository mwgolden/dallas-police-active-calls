data "aws_iam_policy_document" "lambda_policy_downloader_address" {
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
      resources = [ "${var.police_data_bucket_arn}", "${var.police_data_bucket_arn}/*" ]
    }

    statement {
      effect = "Allow"
      actions = [ 
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [ "${aws_sqs_queue.address_processing_queue.arn}" ]
    }

    statement {
      effect = "Allow"
      actions = [ 
        "sqs:SendMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [ "${aws_sqs_queue.geocode_address_processing_queue.arn}" ]
    }

    statement {
      effect = "Allow"
      actions = [ 
        "dynamodb:*"
       ]
       resources = [ "${aws_dynamodb_table.address_cache.arn}" ]
    }

}