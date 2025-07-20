module "flyctl_deploy_token" {
  source = "./modules/fly_deploy_token"
  fly_zip_path = var.fly_zip_path
  fly_token_param_name = var.fly_token_param_name
  fly_app_name = var.fly_app_name
}