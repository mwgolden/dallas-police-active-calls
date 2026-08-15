data "aws_dynamodb_table" "api_config_table" {
    name = local.api_config_table
}

data "aws_iam_policy_document" "lambda_assume_role" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}


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
      resources = [ "${var.police_data_bucket_arn}", "${var.police_data_bucket_arn}/*" ]
    }

    statement {
      effect = "Allow"
      actions = [ 
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchGetItem",
        "dynamodb:GetRecords"
       ]
       resources = [ data.aws_dynamodb_table.api_config_table.arn ]
    }
}

resource "aws_iam_policy" "lambda_policy" {
    name = "dpd_active_calls_downloader_policy"
    path = "/"
    description = "AWS IAM Policy for DPD Active Calls Downloader lambda"
    policy = data.aws_iam_policy_document.lambda_policy_downloader.json
}

resource "aws_iam_role" "lambda_role" {
    name = "dpd_active_calls_downloader"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_role" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy.arn
}