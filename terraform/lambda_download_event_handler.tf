resource "aws_iam_role" "lambda_role_event_handler" {
    name = "dpd_active_calls_download_event_handler"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_policy_event_handler" {
    name = "dpd_active_calls_download_event_handler_policy"
    path = "/"
    description = "AWS IAM Poplicy for DPD Active Calls transformer lambda"
    policy = data.aws_iam_policy_document.lambda_policy_event_handler.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_event_handler_role" {
    role = aws_iam_role.lambda_role_event_handler.name
    policy_arn = aws_iam_policy.lambda_policy_event_handler.arn
}

data "archive_file" "deploy_dpd_active_calls_download_event_handler" {
    type = "zip"
    source_dir = "../lambda/build/dpd_active_calls_download_event_handler/"
    output_path = "../lambda/deploy/dpd-active-calls-download-event-handler.zip"
}


resource "aws_lambda_function" "dpd_active_calls_download_event_handler_lambda" {
    filename = "../lambda/deploy/dpd-active-calls-download-event-handler.zip"
    function_name = "dpd_active_calls_download_event_handler"
    role = aws_iam_role.lambda_role_event_handler.arn
    handler = "app.lambda_handler"
    runtime = "python3.12"
    depends_on = [ aws_iam_role_policy_attachment.attach_iam_policy_to_event_handler_role ]
    source_code_hash = data.archive_file.deploy_dpd_active_calls_download_event_handler.output_base64sha256
    timeout = 60
    environment {
      variables = {
        #ADDRESS_QUEUE_URL = "https://sqs.${local.region}.amazonaws.com/${local.account_id}/dpd-active-calls-process-address-queue"
        #CHANGE_PROCESS_QUEUE = "https://sqs.${local.region}.amazonaws.com/${local.account_id}/dpd-active-calls-process-changes-queue"
        #ADDRESS_CACHE_TABLE = "${aws_dynamodb_table.address_cache.id}"
        ACTIVE_CALLS_TABLE = "${aws_dynamodb_table.dpd_active_calls.id}"
        FILE_CACHE = "${aws_dynamodb_table.dpd_active_calls_file_cache.id}"
        TTL_SECONDS = "129600"
      }
    }
    layers = [ "${aws_lambda_layer_version.utils.arn}", "${aws_lambda_layer_version.dynamodb_utils.arn}" ]
}