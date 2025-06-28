data "aws_iam_policy_document" "dynamodb_ro" {
    statement {
      effect = "Allow"
       actions = [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:DescribeTable"
      ]
      resources = [ "${aws_dynamodb_table.dpd_active_calls.arn}", "${aws_dynamodb_table.address_cache.arn}" ]
    }
}