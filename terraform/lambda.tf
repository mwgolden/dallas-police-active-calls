resource "aws_iam_role" "lambda_role" {
    name = "dpd_active_calls_downloader"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_policy" {
    name = "dpd_active_calls_downloader_policy"
    path = "/"
    description = "AWS IAM Poplicy for DPD Active Calls Downloader lambda"
    policy = data.aws_iam_policy_document.Lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_role" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "null_resource" "build_dpd_active_calls_downloader" {
  provisioner "local-exec" {
    command = "..lambda/build.sh dpd_active_calls_downloader build/dpd_active_calls_downloader"
  }
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
    filename = "../lambda/build/dpd-active-calls-downloader.zip"
    function_name = "dpd_active_calls_downloader"
    role = aws_iam_role.lambda_role.arn
    handler = "app.lambda_handler"
    runtime = "python3.12"
    depends_on = [ aws_iam_role_policy_attachment.attach_iam_policy_to_role ]
    source_code_hash = data.archive_file.build_dpd_active_calls_downloader.output_base64sha256
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