data "aws_lambda_function" "fn_query_rest_api" {
    function_name = "query_rest_api"
}

data "aws_iam_policy_document" "lambda_policy_geocoder" {
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
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
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

    statement {
        effect = "Allow"
        actions = [ 
          "lambda:InvokeFunction"
        ]
        resources = [ data.aws_lambda_function.fn_query_rest_api.arn ]
      }
}