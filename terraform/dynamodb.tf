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
      attribute_name = "TimeToExist"
      enabled = true
      
    }
}

resource "aws_dynamodb_table" "dpd_active_calls" {

    hash_key = "incident_number"
    range_key = "unit_number"
    name = "dpd_active_calls"
    read_capacity = 1
    write_capacity = 1
    attribute {
      name = "incident_number"
      type = "S"
    }

    attribute {
      name = "unit_number"
      type = "S"
    }
    
    ttl {
      attribute_name = "TimeToExist"
      enabled = true
      
    }
}