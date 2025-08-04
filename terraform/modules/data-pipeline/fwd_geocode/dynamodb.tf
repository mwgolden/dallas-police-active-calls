resource "aws_dynamodb_table" "address_cache" {

    hash_key = "address_id"
    name = "address_cache"
    read_capacity = 1
    write_capacity = 1
    stream_enabled = true
    stream_view_type = "NEW_IMAGE"
    attribute {
      name = "address_id"
      type = "S"
    }
    
    ttl {
      attribute_name = "expires_on"
      enabled = true
      
    }
}