# subnets for ECS task

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}
resource "aws_subnet" "subnet_p2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
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

resource "aws_route_table_association" "public1" {
  depends_on     = [aws_subnet.subnet]
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.subnet.id
}

resource "aws_route_table_association" "public2" {
  depends_on     = [aws_subnet.subnet_p2]
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.subnet_p2.id
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

resource "aws_security_group" "alb_security_group" {
    name = "dpd_lb_security_group"
    description = "Allow inbound web traffic on port 80 from anywhere"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    ingress {
        from_port = 443
        to_port = 443
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

resource "aws_security_group" "container_security_group" {
    name = "lb_container_security_group"
    description = "Allow inbound traffic from ALB "
    vpc_id = aws_vpc.main.id
    
    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        security_groups = [ aws_security_group.alb_security_group.id ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}