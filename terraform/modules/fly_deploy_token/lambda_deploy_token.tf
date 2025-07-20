resource "aws_iam_role" "lambda_role_deploy_token" {
    name = "flyctl_get_deploy_token"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_policy_ssm_ro" {
    name = "flyctl_deploy_token"
    path = "/"
    description = "Allow lambda access to get ssm parameter"
    policy = data.aws_iam_policy_document.flyctl_pat_read_only.json
}

resource "aws_iam_role_policy_attachment" "attach_ssm_ro" {
    role = aws_iam_role.lambda_role_deploy_token.name
    policy_arn = aws_iam_policy.lambda_policy_ssm_ro.arn
}

data "archive_file" "deploy_lambda_deploy_token" {
    type = "zip"
    source_dir =  "../lambda/build/fly_io_deploy_token"
    output_path = "../lambda/deploy/fly_io_deploy_token.zip"
}

resource "aws_lambda_function" "flyctl_deploy_token_lambda" {
    filename = data.archive_file.deploy_lambda_deploy_token.output_path
    function_name = "flyctl_get_deploy_token"
    role = aws_iam_role.lambda_role_deploy_token.arn
    handler = "app.lambda_handler"
    runtime = "python3.12"
    depends_on = [aws_iam_role_policy_attachment.attach_ssm_ro ]
    source_code_hash = data.archive_file.deploy_lambda_deploy_token.output_base64sha256
    timeout = 60
    layers = [ "${aws_lambda_layer_version.flyctl_layer.arn}",  ]
    environment {
        variables = {
            FLY_TOKEN_PARAM = var.fly_token_param_name,
            APPLICATION_NAME = var.fly_app_name
        }
    }
}
