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
    source_dir = var.lambda_radar_geocoder_handler_src_dir
    output_path = var.lambda_radar_geocoder_zip_dir
}


resource "aws_lambda_function" "dpd_forward_geocoder_lambda" {
    filename = var.lambda_radar_geocoder_zip_dir
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
    layers = [ "${var.utils_layer}", "${var.dynamodb_utils_layer}" ]
    reserved_concurrent_executions = 1
}