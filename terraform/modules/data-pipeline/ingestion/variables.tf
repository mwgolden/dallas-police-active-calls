variable "police_data_bucket_arn" {
  type = string
  description = "The arn of the s3 bucket where police data will be downloaded."
}

variable "police_data_bucket_id" {
  type = string
  description = "The id of the s3 bucket where police data will be downloaded."
}

variable "lambda_downloader_archive_src_dir" {
  type = string
  description = "Source directory path for the downloader lambda"
}

variable "lambda_downloader_zip_dir" {
  type = string
  description = "Output directory path for the zipped lambda function"
}