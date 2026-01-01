locals {
  envs = var.environments
  # Shorten project name for resource names (AWS has 32 char limit for ALB/target groups)
  short_name = substr(var.project_name, 0, min(14, length(var.project_name)))
}

# SECURITY GROUP
resource "aws_security_group" "alb_sg" {
  for_each = toset(local.envs)

  name        = "${var.project_name}-${each.key}-alb-sg"
  description = "ALB security group for ${each.key}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound to instances"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
resource "aws_lb" "this" {
  for_each = toset(local.envs)

  name               = "${local.short_name}-${each.key}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg[each.key].id]
  subnets            = var.public_subnets
}

# BLUE TARGET GROUP
resource "aws_lb_target_group" "blue" {
  for_each = toset(local.envs)

  name                 = "${local.short_name}-${each.key}-blue-tg"
  port                 = 5000
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 60

  health_check {
    path                = "/health"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# GREEN TARGET GROUP
resource "aws_lb_target_group" "green" {
  for_each = toset(local.envs)

  name     = "${local.short_name}-${each.key}-green-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# LISTENER
resource "aws_lb_listener" "listener" {
  for_each = toset(local.envs)

  load_balancer_arn = aws_lb.this[each.key].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue[each.key].arn
  }
}
