data "archive_file" "deploy_lambda_layer_dynamodb_utils" {
    type = "zip"
    source_dir = var.dynamodb_utils_archive_src_dir
    output_path = var.dynamodb_utils_archive_zip_dir
}

resource "aws_lambda_layer_version" "dynamodb_utils" {
    filename = data.archive_file.deploy_lambda_layer_dynamodb_utils.output_path
    layer_name = "dpd_layer_dynamodb_utils"
    source_code_hash = data.archive_file.deploy_lambda_layer_dynamodb_utils.output_base64sha256
}