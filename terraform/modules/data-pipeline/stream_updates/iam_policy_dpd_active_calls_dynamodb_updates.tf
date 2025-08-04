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
      resources = [ "${var.police_data_bucket_arn}", "${var.police_data_bucket_arn}/*" ]
    }

    statement {
      effect = "Allow"
      actions = ["lambda:InvokeFunction"]
      resources = [ "${var.dynamodb_dpd_active_calls_table_arn}", "${var.dynamodb_address_cache_table_arn}" ]
    }

    statement {
      effect = "Allow"
      actions = [ 
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
       ]
       resources = [ "${var.dynamodb_dpd_active_calls_table_arn}/stream/*", "${var.dynamodb_address_cache_table_arn}/stream/*" ]
    }
    
    statement {
      effect = "Allow"
      actions = [ "ssm:GetParameter" ]
      resources = [ "${var.outbound_api_key_param}" ]
    }
}