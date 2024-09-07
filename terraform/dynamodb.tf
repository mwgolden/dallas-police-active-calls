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