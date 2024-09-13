resource "aws_iam_role" "lambda_role" {
    name = "dpd_active_calls_downloader"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_policy" {
    name = "dpd_active_calls_downloader_policy"
    path = "/"
    description = "AWS IAM Poplicy for DPD Active Calls Downloader lambda"
    policy = data.aws_iam_policy_document.lambda_policy_downloader.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_role" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy.arn
}

data "archive_file" "deploy_dpd_active_calls_downloader" {
    type = "zip"
    source_dir = "../lambda/build/dpd_active_calls_downloader/"
    output_path = "../lambda/deploy/dpd-active-calls-downloader.zip"
}

data "aws_lambda_function" "fn_query_rest_api" {
    function_name = "query_rest_api"
}

resource "aws_lambda_function" "dpd_active_calls_downloader_lambda" {
    filename = "../lambda/deploy/dpd-active-calls-downloader.zip"
    function_name = "dpd_active_calls_downloader"
    role = aws_iam_role.lambda_role.arn
    handler = "app.lambda_handler"
    runtime = "python3.12"
    depends_on = [ aws_iam_role_policy_attachment.attach_iam_policy_to_role ]
    source_code_hash = data.archive_file.deploy_dpd_active_calls_downloader.output_base64sha256
    timeout = 60
    environment {
        variables = {
            DPD_ACTIVE_CALLS_ENDPOINT = "https://www.dallasopendata.com/resource/9fxf-t2tr.json",
            BOT_NAME = "police_active_calls",
            BUCKET_NAME = "com.wgolden.dallas-police-active-calls",
            FOLDER = "raw",
            LAMBDA_TO_INVOKE = "query_rest_api"
        }
    }
}


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
        ADDRESS_QUEUE_URL = "https://sqs.${local.region}.amazonaws.com/${local.account_id}/dpd-active-calls-process-address-queue"
        CHANGE_PROCESS_QUEUE = "https://sqs.${local.region}.amazonaws.com/${local.account_id}/dpd-active-calls-process-changes-queue"
        ADDRESS_CACHE_TABLE = "${aws_dynamodb_table.address_cache.id}"
        FILE_CACHE = "${aws_dynamodb_table.dpd_active_calls_file_cache.id}"
        TTL_SECONDS = "129600"
      }
    }
}

resource "aws_iam_role" "lambda_role_geocoder" {
    name = "dpd_forward_geocoder"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_policy_geocoder" {
    name = "dpd_forward_geocoder_policy"
    path = "/"
    description = "AWS IAM Policy for DPD Active Calls forard geocoding"
    policy = data.aws_iam_policy_document.lambda_policy_geocoder.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_geocoder_role" {
    role = aws_iam_role.lambda_role_geocoder.name
    policy_arn = aws_iam_policy.lambda_policy_geocoder.arn
}

data "archive_file" "deploy_forward_geocoder" {
    type = "zip"
    source_dir = "../lambda/build/dpd_forward_geocoder/"
    output_path = "../lambda/deploy/dpd-forward-geocoder.zip"
}


resource "aws_lambda_function" "dpd_forward_geocoder_lambda" {
    filename = "../lambda/deploy/dpd-forward-geocoder.zip"
    function_name = "dpd_active_calls_forward_geocoder"
    role = aws_iam_role.lambda_role_geocoder.arn
    handler = "app.lambda_handler"
    runtime = "python3.12"
    depends_on = [ aws_iam_role_policy_attachment.attach_iam_policy_to_geocoder_role ]
    source_code_hash = data.archive_file.deploy_forward_geocoder.output_base64sha256
    timeout = 60
    environment {
      variables = {
        ADDRESS_CACHE_TABLE = "${aws_dynamodb_table.address_cache.id}"
        RADAR_ENDPOINT = "https://api.radar.io/v1/geocode/forward"
        LAMBDA_TO_INVOKE = "query_rest_api"
        TTL_SECONDS = "129600"
      }
    }
}

/*
resource "aws_lambda_permission" "allow_event_bridge" {
  statement_id = "AllowExecutionFromEventBridge"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dpd_active_calls_downloader_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.every_2_minutes.arn
}
*/