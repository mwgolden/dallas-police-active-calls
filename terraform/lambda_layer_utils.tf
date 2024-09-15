data "archive_file" "deploy_lambda_layer_utils" {
    type = "zip"
    source_dir = "../lambda/build/layer_utilities/"
    output_path = "../lambda/deploy/dpd_layer_utilities.zip"
}

resource "aws_lambda_layer_version" "utils" {
    filename = data.archive_file.deploy_lambda_layer_utils.output_path
    layer_name = "dpd_layer_utilities"
    source_code_hash = data.archive_file.deploy_lambda_layer_utils.output_base64sha256
}