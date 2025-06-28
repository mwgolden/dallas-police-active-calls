
resource "aws_api_gateway_rest_api" "dpd_active_calls_api" {
  name = "DPD Active Callas API"
}

resource "aws_api_gateway_resource" "get_current_calls" {
  rest_api_id = aws_api_gateway_rest_api.dpd_active_calls_api.id
  parent_id = aws_api_gateway_rest_api.dpd_active_calls_api.root_resource_id
  path_part = "current_calls"
}

resource "aws_api_gateway_method" "get_current_calls" {
    rest_api_id = aws_api_gateway_rest_api.dpd_active_calls_api.id
    resource_id = aws_api_gateway_resource.get_current_calls.id
    http_method = "GET"
    authorization = "NONE"
    api_key_required = true
}

resource "aws_api_gateway_integration" "lambda_current_calls_integration" {
  rest_api_id = aws_api_gateway_rest_api.dpd_active_calls_api.id
  resource_id = aws_api_gateway_resource.get_current_calls.id
  http_method = aws_api_gateway_method.get_current_calls.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.dpd_active_calls_current_calls_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.dpd_active_calls_current_calls_lambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${ aws_api_gateway_rest_api.dpd_active_calls_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [ aws_api_gateway_integration.lambda_current_calls_integration ]
  rest_api_id = aws_api_gateway_rest_api.dpd_active_calls_api.id
}

resource "aws_api_gateway_stage" "prod_stage" {
    deployment_id = aws_api_gateway_deployment.deployment.id
    rest_api_id = aws_api_gateway_rest_api.dpd_active_calls_api.id
    stage_name = "prod"
}

resource "aws_api_gateway_api_key" "api_key" {
  name = "dpd-active-calls-api-key"
  enabled = true
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "BasicUsagePlan"
  api_stages {
    api_id = aws_api_gateway_rest_api.dpd_active_calls_api.id
    stage  = aws_api_gateway_stage.prod_stage.stage_name
  }

  throttle_settings {
    rate_limit  = 3
    burst_limit = 3
  }
}

resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}