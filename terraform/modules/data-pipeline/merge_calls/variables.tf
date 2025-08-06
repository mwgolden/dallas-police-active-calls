variable "s3_create_object_topic_arn" {
    type = string
    description = "SNS Topic that notifies this module a new file was downloaded from source"  
}

variable "police_data_bucket_arn" {
  type = string
  description = "The arn of the s3 bucket where police data will be downloaded."
}

variable "lambda_downloader_archive_src_dir" {
  type = string
  description = "Source directory path for the downloader lambda"
}

variable "lambda_downloader_zip_dir" {
  type = string
  description = "Output directory path for the zipped lambda function"
}

variable "utils_layer" {
  type = string
  description = "The arn of utils lambda layer"
}

variable "dynamodb_utils_layer" {
  type = string
  description = "The arn of dynamodb utils lambda layer"
}