data "archive_file" "deploy_dpd_active_calls_downloader" {
    type = "zip"
    source_dir = var.lambda_downloader_archive_src_dir
    output_path = var.lambda_downloader_zip_dir
}

data "aws_lambda_layer_version" "api_token_cache" {
  layer_name = "layer_api_token_cache"
}

resource "aws_lambda_function" "dpd_active_calls_downloader_lambda" {
    filename = var.lambda_downloader_zip_dir
    function_name = "dpd_active_calls_downloader"
    role = aws_iam_role.lambda_role.arn
    handler = "app.lambda_handler"
    runtime = "python3.12"
    depends_on = [ aws_iam_role_policy_attachment.attach_iam_policy_to_role ]
    source_code_hash = data.archive_file.deploy_dpd_active_calls_downloader.output_base64sha256
    timeout = 60
    layers = [ data.aws_lambda_layer_version.api_token_cache.arn ]
    environment {
        variables = {
            DPD_ACTIVE_CALLS_ENDPOINT = "https://www.dallasopendata.com/resource/9fxf-t2tr.json",
            BOT_NAME = "police_active_calls",
            BUCKET_NAME = "com.wgolden.dallas-police-active-calls",
            FOLDER = "raw",
            "API_CONFIG_TABLE" = "api_bot_config",
            "API_TOKEN_CACHE_TABLE" = "api_token_cache"
        }
    }
}


resource "aws_lambda_permission" "allow_event_bridge" {
  statement_id = "AllowExecutionFromEventBridge"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dpd_active_calls_downloader_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.every_5_minutes.arn
}
