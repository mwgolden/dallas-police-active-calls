resource "aws_lb" "dpd_active_calls_lb" {
    name = "dpd-active-calls-lb"
    load_balancer_type = "application"
    idle_timeout = 1800
    security_groups = [ aws_security_group.alb_security_group.id ]
    subnets = [ aws_subnet.subnet.id, aws_subnet.subnet_p2.id ]
}

resource "aws_lb_target_group" "dpd_active_calls_target_group" {
    depends_on = [ aws_lb.dpd_active_calls_lb ]
    name = "dpd-active-calls-lb-tgt"
    port = 8000
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = aws_vpc.main.id
}

resource "aws_lb_listener" "dpd_active_calls_lb_listener" {
    load_balancer_arn = aws_lb.dpd_active_calls_lb.arn
    port = "80"
    protocol = "HTTP"
    depends_on = [ aws_lb_target_group.dpd_active_calls_target_group ]

    default_action {
      type = "redirect"
      redirect {
        port = 443
        protocol = "HTTPS"
        status_code = "HTTP_301"
      }
    }
}

resource "aws_lb_listener" "https" {
    load_balancer_arn = aws_lb.dpd_active_calls_lb.arn
    port = 443
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-2016-08"
    certificate_arn = local.aws_acm_certificate_arn
    depends_on = [ aws_lb_target_group.dpd_active_calls_target_group ]

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.dpd_active_calls_target_group.arn
    }
}