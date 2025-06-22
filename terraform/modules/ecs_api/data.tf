data "aws_acm_certificate" "issued" {
    domain = "*.dallaspolicecalls.com"
    statuses = [ "ISSUED" ]
}