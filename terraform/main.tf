data "aws_lambda_function" "fn_query_rest_api" {
    function_name = "query_rest_api"
}

module "data_ingestion" {
  source = "./modules/data-pipeline/ingestion"
  police_data_bucket_arn = "${aws_s3_bucket.police_data.arn}"
  lambda_downloader_archive_src_dir = "../lambda/build/dpd_active_calls_downloader/"
  lambda_downloader_zip_dir = "../lambda/deploy/dpd-active-calls-downloader.zip"
}


module "flyctl_deploy_token" {
  source = "./modules/fly_deploy_token"
  fly_zip_path = var.fly_zip_path
  fly_token_param_name = var.fly_token_param_name
  fly_app_name = var.fly_app_name
}