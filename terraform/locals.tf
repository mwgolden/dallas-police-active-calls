data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
    account_id = data.aws_caller_identity.current.account_id
    region = data.aws_region.current.name
    ecs_container_name = "dpd-active-calls-api"
    ecr_repository = "repository/com.wgolden.dpd-active-calls-api"
}