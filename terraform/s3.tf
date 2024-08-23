resource "aws_s3_bucket" "police_data" {
    bucket = "com.wgolden.dallas-police-active-calls"
    force_destroy = true
    tags = {
        Name = "Dallas Police Active Calls"
        Terraform = "true"
    }
}