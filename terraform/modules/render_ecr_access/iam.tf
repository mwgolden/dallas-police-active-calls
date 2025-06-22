resource "aws_iam_user" "render_user" {
    name = "render_ecr_access"
    path = "/dpd_active_calls"
    force_destroy = true

    tags = {
        application = "dallas-police-active-calls"
    }
}