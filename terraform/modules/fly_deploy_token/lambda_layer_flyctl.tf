
resource "aws_lambda_layer_version" "flyctl_layer" {
    filename = var.fly_zip_path
    layer_name = "flyctl_layer"
}