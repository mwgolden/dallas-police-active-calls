data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_acm_certificate" "issued" {
    domain = "*.dallaspolicecalls.com"
    statuses = [ "ISSUED" ]
}

locals {
    account_id = data.aws_caller_identity.current.account_id
    region = data.aws_region.current.name
    ecs_container_name = "dpd-active-calls-api"
    aws_acm_certificate_arn =data.aws_acm_certificate.issued.arn
}