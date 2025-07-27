data "aws_ssm_parameter" "flyctl_pat_parameter" {
  name = var.fly_token_param_name
}

data "aws_iam_policy_document" "flyctl_pat_read_only" {
    statement {
      effect = "Allow"
      actions = [ "ssm:GetParameter" ]
      resources = [ data.aws_ssm_parameter.flyctl_pat_parameter.arn ]
    }
}

data "aws_iam_policy_document" "lambda_assume_role" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}