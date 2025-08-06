variable "police_data_bucket_arn" {
  type = string
  description = "The arn of the s3 bucket where police data will be downloaded."
}

variable "dynamodb_dpd_active_calls_table_arn" {
  type = string
  description = "ARN of the dpd_active_calls dynamodb table"
}

variable "dynamodb_address_cache_table_arn" {
  type = string
  description = "ARN of the address cache dynamodb table"
}

variable "outbound_api_key_param" {
  type = string
  description = "ARN of ssm parameter for the outbound api key"
}

variable "api_event_push_url" {
  type = string
  description = "URL of api to push call events"
}

variable "utils_layer" {
  type = string
  description = "The arn of utils lambda layer"
}

variable "dynamodb_utils_layer" {
  type = string
  description = "The arn of dynamodb utils lambda layer"
}

variable "address_cache_event_src_arn" {
  type = string
  description = "ARN of the dynamodb event stream"
}

variable "active_calls_event_src_arn" {
  type = string
  description = "ARN of the dynamodb event stream"
}