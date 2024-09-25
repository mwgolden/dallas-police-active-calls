resource "aws_dynamodb_table" "address_cache" {

    hash_key = "address_id"
    name = "address_cache"
    read_capacity = 1
    write_capacity = 1
    attribute {
      name = "address_id"
      type = "S"
    }
    
    ttl {
      attribute_name = "expires_on"
      enabled = true
      
    }
}

resource "aws_dynamodb_table" "dpd_active_calls" {

    hash_key = "call_id"
    range_key = "update_date"
    name = "dpd_active_calls"
    read_capacity = 1
    write_capacity = 1
    stream_enabled = true
    stream_view_type = "NEW_IMAGE"
    attribute {
      name = "call_id"
      type = "S"
    }

    attribute {
      name = "update_date"
      type = "S"
    }
    
    ttl {
      attribute_name = "expires_on"
      enabled = true
      
    }
}

resource "aws_dynamodb_table" "dpd_active_calls_file_cache" {

    hash_key = "s3_bucket"
    name = "dpd_active_calls_file_cache"
    read_capacity = 1
    write_capacity = 1
    attribute {
      name = "s3_bucket"
      type = "S"
    }
    
    ttl {
      attribute_name = "expires_on"
      enabled = true
      
    }
}