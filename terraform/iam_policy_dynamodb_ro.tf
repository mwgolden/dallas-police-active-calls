data "aws_iam_policy_document" "dynamodb_ro" {
    statement {
      effect = "Allow"
       actions = [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:DescribeTable"
      ]
      resources = [ "${module.merge_calls.dpd_active_calls_dynamodb_table_arn}", "${module.fwd_geocode_address.address_cache_dynamodb_table_arn}" ]
    }
}