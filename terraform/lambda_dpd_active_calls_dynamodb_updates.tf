resource "aws_iam_role" "lambda_role_dynamodb_updates" {
    name = "dpd_active_calls_dynamodb_updates"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_policy_dynamodb_updates" {
    name = "dpd_active_calls_dynamodb_updates_policy"
    path = "/"
    description = "AWS IAM Poplicy for DPD Active Calls dynamodb updates lambda"
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
            FOLDER = "updates/active_calls",
        }
    }
    layers = [ "${aws_lambda_layer_version.utils.arn}", "${aws_lambda_layer_version.dynamodb_utils.arn}" ]
}

resource "aws_lambda_event_source_mapping" "lambda_dynamodb" {
  event_source_arn  = aws_dynamodb_table.dpd_active_calls.stream_arn
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