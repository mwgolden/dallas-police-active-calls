resource "aws_iam_role" "lambda_role_dynamodb_updates" {
    name = "dpd_active_calls_dynamodb_updates"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_policy_dynamodb_updates" {
    name = "dpd_active_calls_dynamodb_updates_policy"
    path = "/"
    description = "AWS IAM Policy for DPD Active Calls dynamodb updates lambda"
    policy = data.aws_iam_policy_document.lambda_policy_dynamodb_updates.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_dynamodb_updates_to_role" {
    role = aws_iam_role.lambda_role_dynamodb_updates.name
    policy_arn = aws_iam_policy.lambda_policy_dynamodb_updates.arn
}

data "archive_file" "deploy_dpd_active_calls_dynamodb_updates" {
    type = "zip"
    source_dir = "../lambda/build/dpd_active_calls_dynamodb_updates/"
    output_path = "../lambda/deploy/dpd-active-calls-dynamodb-updates.zip"
}

resource "aws_lambda_function" "dpd_active_calls_dynamodb_updates_lambda" {
    filename = "../lambda/deploy/dpd-active-calls-dynamodb-updates.zip"
    function_name = "dpd_active_calls_dynamodb_updates"
    role = aws_iam_role.lambda_role_dynamodb_updates.arn
    handler = "app.lambda_handler"
    runtime = "python3.12"
    depends_on = [ aws_iam_role_policy_attachment.attach_iam_policy_dynamodb_updates_to_role ]
    source_code_hash = data.archive_file.deploy_dpd_active_calls_dynamodb_updates.output_base64sha256
    timeout = 60
    environment {
        variables = {
            BUCKET_NAME = "com.wgolden.dallas-police-active-calls",
            CALLS_FOLDER = "updates/active_calls",
            ADDRESS_FOLDER = "updates/locations",
            EVENT_URL = var.api_event_push_url
        }
    }
    layers = [ "${var.utils_layer}", "${var.dynamodb_utils_layer}" ]
}

resource "aws_lambda_event_source_mapping" "lambda_dynamodb" {
  event_source_arn  = var.active_calls_event_src_arn
  function_name     = aws_lambda_function.dpd_active_calls_dynamodb_updates_lambda.arn
  starting_position = "LATEST"
  filter_criteria {
    filter {
      pattern = jsonencode({
        "eventName": ["INSERT"]
      })
    }
  }
}

resource "aws_lambda_event_source_mapping" "new_address_dynamodb" {
  event_source_arn  = var.address_cache_event_src_arn
  function_name     = aws_lambda_function.dpd_active_calls_dynamodb_updates_lambda.arn
  starting_position = "LATEST"
  filter_criteria {
    filter {
      pattern = jsonencode({
        "eventName": ["INSERT"]
      })
    }
  }
}
