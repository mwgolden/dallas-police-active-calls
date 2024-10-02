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
        })
    execution_role_arn = aws_iam_role.ecs_role.arn
    task_role_arn = aws_iam_role.ecs_role.arn
 }

 # Security group for ECS tasks
 resource "aws_security_group" "ecs_security_group" {
    name = "ecs_security_group"
    description = "Alow inbound access to dpd active calls api"
    vpc_id = aws_vpc.main.id
    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

# subnets for ECS task

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "igw" {
  provider = aws
  vpc_id   = aws_vpc.main.id
  tags = {
    Name      = "Internet Gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.subnet]
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.subnet.id
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
    subnets = [ aws_subnet.subnet.id ]
    security_groups = [ aws_security_group.ecs_security_group.id ]
    assign_public_ip = true
  }
}