variable "dynamodb_utils_archive_src_dir" {
  type = string
  description = "Source build directory for dynamodb layer utils"
}

variable "dynamodb_utils_archive_zip_dir" {
  type = string
  description = "Output directory for dynamodb layer utils"
}

variable "lambda_layer_utils_archive_src_dir" {
  type = string
  description = "Source build directory for lambda layer utils"
}

variable "lambda_layer_utils_archive_zip_dir" {
  type = string
  description = "Output directory for lambda layer utils"
}
