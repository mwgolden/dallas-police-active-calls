data "aws_caller_identity" "account" {}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "ecs_task_role" {
  
  statement {
    effect = "Allow"
    actions = [
      "ecr:*",
      "logs:*"
    ]
    resources = [ "*" ]
  }

  statement {
      effect = "Allow"
      actions = [ 
        "dynamodb:Query",
        "dynamodb:GetItem",
        "dynamodb:Scan"
      ]
      resources = [ aws_dynamodb_table.address_cache.arn, aws_dynamodb_table.dpd_active_calls.arn ]
    }   
}


 resource "aws_iam_role" "ecs_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_policy" "ecs_policy" {
  name        = "aws_ecs_policy"
  description = "AWS IAM Policy for managing aws ecs role"
  policy      = data.aws_iam_policy_document.ecs_task_role.json
}

resource "aws_iam_role_policy_attachment" "attach_ecs_iam_policy_to_role" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = aws_iam_policy.ecs_policy.arn
}

resource "aws_ecs_cluster" "ecs_cluster" {
    name = "dpd-active-calls-api-cluster"
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name  = "/ecs/dpd-active-calls-api-logs"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "dpd_active_calls_api" {
    family = "dpd-active-calls-api"
    requires_compatibilities = [ "FARGATE" ]
    network_mode = "awsvpc"
    cpu = 256
    memory = 1024
    container_definitions = templatefile(
        "${path.module}/ecs.api.def.json", 
        { 
            account_number = data.aws_caller_identity.account.account_id 
            ecs_container_name = var.ecs_container_name
        })
    execution_role_arn = aws_iam_role.ecs_role.arn
    task_role_arn = aws_iam_role.ecs_role.arn
 }

# ECS Service Networking Config
resource "aws_ecs_service" "api_service" {
  name = "dpd-active-calls-api-service"
  cluster = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.dpd_active_calls_api.arn
  desired_count = 1
  launch_type =  "FARGATE"
  enable_ecs_managed_tags = true

  network_configuration {
    subnets = [ aws_subnet.subnet.id, aws_subnet.subnet_p2.id ]
    security_groups = [ aws_security_group.ecs_security_group.id, aws_security_group.container_security_group.id ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dpd_active_calls_target_group.arn
    container_name = var.ecs_container_name
    container_port = 8000
  }
}

