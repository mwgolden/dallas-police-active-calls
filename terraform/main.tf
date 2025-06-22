module "render_ecr_access" {
    source = "./modules/render_ecr_access"
    aws_region = local.region
    aws_account_id = local.account_id
    ecr_repository = local.ecr_repository
}