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
    range_key = "update_dt"
    name = "dpd_active_calls"
    read_capacity = 1
    write_capacity = 1
    attribute {
      name = "call_id"
      type = "S"
    }

    attribute {
      name = "update_dt"
      type = "S"
    }
    
    ttl {
      attribute_name = "expires_on"
      enabled = true
      
    }
}