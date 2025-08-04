data "archive_file" "deploy_lambda_layer_utils" {
    type = "zip"
    source_dir = var.lambda_layer_utils_archive_src_dir
    output_path = var.lambda_layer_utils_archive_zip_dir
}

resource "aws_lambda_layer_version" "utils" {
    filename = data.archive_file.deploy_lambda_layer_utils.output_path
    layer_name = "dpd_layer_utilities"
    source_code_hash = data.archive_file.deploy_lambda_layer_utils.output_base64sha256
}