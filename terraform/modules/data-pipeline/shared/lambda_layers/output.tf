output "lambda_layer_utils_arn" {
    value = aws_lambda_layer_version.utils.arn
}

output "dynamodb_utils_arn" {
    value = aws_lambda_layer_version.dynamodb_utils.arn
}