data "aws_lambda_function" "fn_query_rest_api" {
    function_name = "query_rest_api"
}

module "data_pipeline_shared" {
  source = "./modules/data-pipeline/shared/lambda_layers"
  dynamodb_utils_archive_src_dir = "../lambda/build/layer_dynamodb_utils/"
  dynamodb_utils_archive_zip_dir = "../lambda/deploy/dpd_layer_dynamodb.zip"
  lambda_layer_utils_archive_src_dir = "../lambda/build/layer_utilities/"
  lambda_layer_utils_archive_zip_dir = "../lambda/deploy/dpd_layer_utilities.zip"
}

module "data_ingestion" {
  source = "./modules/data-pipeline/ingestion"
  police_data_bucket_arn = "${aws_s3_bucket.police_data.arn}"
  police_data_bucket_id = "${aws_s3_bucket.police_data.id}"
  lambda_downloader_archive_src_dir = "../lambda/build/dpd_active_calls_downloader/"
  lambda_downloader_zip_dir = "../lambda/deploy/dpd-active-calls-downloader.zip"
}

module "merge_calls" {
  source = "./modules/data-pipeline/merge_calls"
  s3_create_object_topic_arn = module.data_ingestion.sns_create_topic_arn
  police_data_bucket_arn = "${aws_s3_bucket.police_data.arn}"
  lambda_downloader_archive_src_dir = "../lambda/build/dpd_active_calls_download_event_handler/"
  lambda_downloader_zip_dir = "../lambda/deploy/dpd-active-calls-download-event-handler.zip"
  utils_layer = module.data_pipeline_shared.lambda_layer_utils_arn
  dynamodb_utils_layer = module.data_pipeline_shared.dynamodb_utils_arn
}

module "fwd_geocode_address" {
  source = "./modules/data-pipeline/fwd_geocode"
  lambda_download_handler_src_dir = "../lambda/build/dpd_active_calls_download_address_handler/"
  lambda_download_handler_zip_dir = "../lambda/deploy/dpd-active-calls-download-address-handler.zip"
  lambda_radar_geocoder_handler_src_dir = "../lambda/build/dpd_forward_geocoder/"
  lambda_radar_geocoder_zip_dir = "../lambda/deploy/dpd-forward-geocoder.zip"
  aws_region = local.region
  aws_account_id = local.account_id
  utils_layer = module.data_pipeline_shared.lambda_layer_utils_arn
  dynamodb_utils_layer = module.data_pipeline_shared.dynamodb_utils_arn
  police_data_bucket_arn = "${aws_s3_bucket.police_data.arn}"
  s3_create_object_topic_arn = module.data_ingestion.sns_create_topic_arn
}

module "stream_updates" {
  source = "./modules/data-pipeline/stream_updates"
  police_data_bucket_arn = "${aws_s3_bucket.police_data.arn}"
  dynamodb_dpd_active_calls_table_arn = module.merge_calls.dpd_active_calls_dynamodb_table_arn
  dynamodb_address_cache_table_arn = module.fwd_geocode_address.address_cache_dynamodb_table_arn
  outbound_api_key_param = "${aws_ssm_parameter.api_key.arn}"
  api_event_push_url = var.api_event_push_url
  utils_layer = module.data_pipeline_shared.lambda_layer_utils_arn
  dynamodb_utils_layer = module.data_pipeline_shared.dynamodb_utils_arn
  address_cache_event_src_arn = module.fwd_geocode_address.address_cache_event_src_arn
  active_calls_event_src_arn = module.merge_calls.active_calls_event_src_arn
}


module "flyctl_deploy_token" {
  source = "./modules/fly_deploy_token"
  fly_zip_path = var.fly_zip_path
  fly_token_param_name = var.fly_token_param_name
  fly_app_name = var.fly_app_name
}