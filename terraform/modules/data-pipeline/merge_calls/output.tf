output "dpd_active_calls_dynamodb_table_arn" {
  description = "ARN of the dpd_active_calls dynamodb table"
  value = aws_dynamodb_table.dpd_active_calls.arn
}

output "active_calls_event_src_arn" {
  description = "ARN of the dynamodb event stream"
  value = aws_dynamodb_table.dpd_active_calls.stream_arn
}