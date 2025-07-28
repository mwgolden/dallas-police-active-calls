resource "aws_iam_openid_connect_provider" "github_provider" {
    url = "https://token.actions.githubusercontent.com"
    client_id_list = [ "sts.amazonaws.com" ]
}


data "aws_iam_policy_document" "github_oidc_policy" {
  statement {
    effect = "Allow"
    actions = [ "sts:AssumeRoleWithWebIdentity" ]
    principals {
      type = "Federated"
      identifiers = [ "${aws_iam_openid_connect_provider.github_provider.arn}" ]
    }
    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = [ "sts.amazonaws.com" ]
    }
    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [ "repo:mwgolden/dallas-police-active-calls:ref:refs/heads/main" ]
    }
  }
}

data "aws_iam_policy_document" "lambda_invoke" {
  statement {
    effect = "Allow"
    actions = [ "lambda:InvokeFunction" ]
    resources = [ "${aws_lambda_function.flyctl_deploy_token_lambda.arn}" ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
    name = "gh-oidc-lambda-invoke"
    path = "/"
    description = "Grant access to invoke lambda for deployment token"
    policy = data.aws_iam_policy_document.lambda_invoke.json
}

resource "aws_iam_role" "github_oidc_lambda" {
  name = "GHActionsOIDCLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_invoke_policy" {
  role = aws_iam_role.github_oidc_lambda.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}