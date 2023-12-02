provider "aws" {
  region = "eu-central-1"
}

# Define a default VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Define subnets
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-central-1a"
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-central-1b"
}

#define gateways

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_eip" "ngw_a" {
  domain = "vpc"
}
resource "aws_eip" "ngw_b" {
  domain = "vpc"
}
resource "aws_nat_gateway" "my_nat_gateway_a" {
  allocation_id = aws_eip.ngw_a.id
  subnet_id     = aws_subnet.public_subnet_a.id
}

resource "aws_nat_gateway" "my_nat_gateway_b" {
  allocation_id = aws_eip.ngw_b.id
  subnet_id     = aws_subnet.public_subnet_b.id
}

#define routs
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private_route_table_a" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat_gateway_a.id
  }

  tags = {
    Name = "private-route-table-a"
  }
}

resource "aws_route_table" "private_route_table_b" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat_gateway_b.id
  }

  tags = {
    Name = "private-route-table-b"
  }
}

resource "aws_route_table_association" "public_subnet_association_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table_a.id
}

resource "aws_route_table_association" "private_subnet_association_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table_b.id
}


# Define security groups
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nginx_sg" {
  name        = "nginx_sg"
  description = "Security group for Nginx"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port = 9980
    to_port   = 9980
    protocol  = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the ECS cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-ecs-cluster"
}

# Define the ALB
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]  # Use the ALB security group

  enable_deletion_protection = false  # Set to true if you want to enable deletion protection
  subnets = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

# Define a target group
resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  protocol    = "HTTP"
  target_type = "ip"
  port = 9980
  vpc_id   = aws_vpc.my_vpc.id
}

# Define a listener for the ALB
resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}


# Define the ECS task definition for MySQL
resource "aws_ecs_task_definition" "mysql_task" {
  family                   = "mysql-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "mysql-container"
    image = "267087166096.dkr.ecr.eu-central-1.amazonaws.com/mysql_repository:latest"
    portMappings = [{
      containerPort = 3306
      hostPort      = 3306
    }]
  }])
}

# Define the ECS service for MySQL
resource "aws_ecs_service" "mysql_service" {
  name            = "mysql-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.mysql_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    security_groups = [aws_security_group.alb_sg.id]
  }
  
}

# Define the ECS task definition for Nginx
resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  depends_on = [ aws_lb_listener.my_listener,aws_lb.my_alb ]
  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "nginx-container"
    image = "267087166096.dkr.ecr.eu-central-1.amazonaws.com/nginx_repository:latest"
    portMappings = [{
      containerPort = 9980
      hostPort      = 9980
    }]
  }])
  
}

# Define the ECS service for Nginx
resource "aws_ecs_service" "nginx_service" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    security_groups = [aws_security_group.nginx_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "nginx-container"
    container_port   = 9980
  }

  depends_on = [aws_lb_target_group.my_target_group]
}

# Define IAM role for ECS execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach AmazonECSTaskExecutionRolePolicy to the ECS execution role
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution_role.name
}
