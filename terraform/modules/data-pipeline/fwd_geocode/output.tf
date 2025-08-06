output "address_cache_dynamodb_table_arn" {
  description = "ARN of the address cache dynamodb table"
  value = aws_dynamodb_table.address_cache.arn
}

output "address_cache_event_src_arn" {
  description = "ARN of the dynamodb event stream"
  value = aws_dynamodb_table.address_cache.stream_arn
}