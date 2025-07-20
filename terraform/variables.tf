variable "aws_profile" {
  type    = string
  default = "default"
}

variable "fly_zip_path" {
  type = string
  description = "path to zipped flyctl binary"
}


variable "fly_token_param_name" {
  type = string
  description = "flyctl token ssm param name"
}

variable "api_event_push_url" {
  type = string
  description = "URL for to push updates for cals and addresses to"
}

variable fly_app_name {
  type = string
  description = "the fly.io application name"
}