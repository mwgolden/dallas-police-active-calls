data "aws_iam_policy_document" "lambda_policy_downloader" {
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
        "lambda:InvokeFunction"
       ]
       resources = [ data.aws_lambda_function.fn_query_rest_api.arn ]
    }
}