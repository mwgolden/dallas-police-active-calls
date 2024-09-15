data "archive_file" "deploy_lambda_layer_dynamodb_utils" {
    type = "zip"
    source_dir = "../lambda/build/layer_dynamodb_utils/"
    output_path = "../lambda/deploy/dpd_layer_dynamodb.zip"
}

resource "aws_lambda_layer_version" "dynamodb_utils" {
    filename = data.archive_file.deploy_lambda_layer_dynamodb_utils.output_path
    layer_name = "dpd_layer_dynamodb_utils"
    source_code_hash = data.archive_file.deploy_lambda_layer_dynamodb_utils.output_base64sha256
}