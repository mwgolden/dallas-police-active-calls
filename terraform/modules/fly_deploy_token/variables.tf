
variable "fly_zip_path" {
  type = string
  description = "local path to zipped flyctl binary"
}

variable "fly_token_param_name" {
  type = string
  description = "The name of the flyctl ssm parameter"
}

variable fly_app_name {
  type = string
  description = "the fly.io application name"
}