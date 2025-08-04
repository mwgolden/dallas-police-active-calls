resource "aws_iam_role" "lambda_role_event_handler_address" {
    name = "dpd_active_calls_download_event_handler_address"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_policy_event_handler_address" {
    name = "dpd_active_calls_download_event_handler_address_policy"
    path = "/"
    description = "AWS IAM Policy for DPD Active Calls transformer lambda"
    policy = data.aws_iam_policy_document.lambda_policy_downloader_address.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_event_handler_address_role" {
    role = aws_iam_role.lambda_role_event_handler_address.name
    policy_arn = aws_iam_policy.lambda_policy_event_handler_address.arn
}

data "archive_file" "deploy_dpd_active_calls_download_event_handler_address" {
    type = "zip"
    source_dir = var.lambda_download_handler_src_dir
    output_path = var.lambda_download_handler_zip_dir
}


resource "aws_lambda_function" "dpd_active_calls_download_event_handler_address_lambda" {
    filename = var.lambda_download_handler_zip_dir
    function_name = "dpd_active_calls_download_event_handler_address"
    role = aws_iam_role.lambda_role_event_handler_address.arn
    handler = "app.lambda_handler"
    runtime = "python3.12"
    depends_on = [ aws_iam_role_policy_attachment.attach_iam_policy_to_event_handler_address_role ]
    source_code_hash = data.archive_file.deploy_dpd_active_calls_download_event_handler_address.output_base64sha256
    timeout = 60
    environment {
      variables = {
        ADDRESS_QUEUE_URL = "https://sqs.${var.aws_region}.amazonaws.com/${var.aws_account_id}/dpd-active-calls-geocode-address-queue"
        ADDRESS_CACHE_TABLE = "${aws_dynamodb_table.address_cache.id}"
        TTL_SECONDS = "129600"
      }
    }
    layers = [ "${var.utils_layer}", "${var.dynamodb_utils_layer}" ]
}