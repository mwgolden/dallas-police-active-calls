resource "aws_iam_role" "lambda_role_current_calls" {
    name = "dpd_active_calls_current_calls"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_policy_current_calls" {
    name = "dpd_active_calls_current_calls"
    path = "/"
    description = "AWS IAM Poplicy for DPD Active Calls Current Calls lambda"
    policy = data.aws_iam_policy_document.dynamodb_ro.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_current_calls_role" {
    role = aws_iam_role.lambda_role_current_calls.name
    policy_arn = aws_iam_policy.lambda_policy_current_calls.arn
}

data "archive_file" "deploy_dpd_active_calls_current_calls" {
    type = "zip"
    source_dir = "../lambda/build/dpd_active_calls_current_calls/"
    output_path = "../lambda/deploy/dpd-active-calls-current-calls.zip"
}

resource "aws_lambda_function" "dpd_active_calls_current_calls_lambda" {
    filename = "../lambda/deploy/dpd-active-calls-current-calls.zip"
    function_name = "dpd_active_calls_current_Calls"
    role = aws_iam_role.lambda_role_current_calls.arn
    handler = "app.lambda_handler"
    runtime = "python3.12"
    environment {
      variables = {
        CALL_TABLE = "dpd_active_calls"
        ADDRESS_CACHE = "address_cache"
      }
    }
    depends_on = [ aws_iam_role_policy_attachment.attach_iam_policy_to_current_calls_role ]
    source_code_hash = data.archive_file.deploy_dpd_active_calls_current_calls.output_base64sha256
    timeout = 60
}


#resource "aws_lambda_permission" "allow_dynamodb_ro" {
#  statement_id = "AllowExecutionFromEventBridge"
#  action = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.dpd_active_calls_downloader_lambda.function_name
#  principal = "events.amazonaws.com"
#  source_arn = aws_cloudwatch_event_rule.every_5_minutes.arn
#}
