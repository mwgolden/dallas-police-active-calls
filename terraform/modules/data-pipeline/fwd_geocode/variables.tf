variable "aws_region" {
  type = string
  description = "aws region"
}

variable "aws_account_id" {
  type = string
  description = "aws account id"
}

variable "lambda_download_handler_src_dir" {
    type = string
    description = "Source directory path for the address download event handler"
}

variable "lambda_download_handler_zip_dir" {
  type = string
  description = "Build path for the address download event handler"
}

variable "lambda_radar_geocoder_handler_src_dir" {
    type = string
    description = "Source directory path for the address radar geocoder"
}

variable "lambda_radar_geocoder_zip_dir" {
  type = string
  description = "Build path for the address radar geocoder"
}

variable "utils_layer" {
  type = string
  description = "The arn of utils lambda layer"
}

variable "dynamodb_utils_layer" {
  type = string
  description = "The arn of dynamodb utils lambda layer"
}

variable "police_data_bucket_arn" {
  type = string
  description = "The arn of the s3 bucket where police data will be downloaded."
}

variable "s3_create_object_topic_arn" {
    type = string
    description = "SNS Topic that notifies this module a new file was downloaded from source"  
}