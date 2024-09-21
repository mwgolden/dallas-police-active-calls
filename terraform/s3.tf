resource "aws_s3_bucket" "police_data" {
    bucket = "com.wgolden.dallas-police-active-calls"
    force_destroy = true
    tags = {
        Name = "Dallas Police Active Calls"
        Terraform = "true"
    }
}

resource "aws_s3_bucket_lifecycle_configuration" "raw_lifecycle_config" {
    bucket = aws_s3_bucket.police_data.id

    rule {
        id = "expire_dpd_active_calls_raw_files"
        status = "Enabled"
        expiration {
          days = 3
        }
        filter {
            prefix = "raw/"
        }
    }
}

    