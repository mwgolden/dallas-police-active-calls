data "aws_iam_policy_document" "ecr_read_only_access" {
    statement {
      effect = "Allow"
      actions = [ "ecr:GetAuthorizationToken" ]
       resources = [ "*" ]
    }

    statement {
      effect = "Allow"
      actions = [ 
        "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer"
       ]
      resources = [ "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:${var.ecr_repository}" ]
    }
}