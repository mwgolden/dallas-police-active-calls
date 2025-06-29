
# create an api key to be used to publish address change events from lambda to the api 

resource "random_password" "api_key" {
    length = 32
    special = false
}

resource "aws_ssm_parameter" "api_key" {
    name = "/dallas_active_calls/api_key"
    description = "API key to submit events to FastAPI server"
    type = "SecureString"
    value = random_password.api_key.result
}