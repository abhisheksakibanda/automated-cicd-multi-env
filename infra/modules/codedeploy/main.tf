resource "aws_codedeploy_app" "app" {
  name             = "${var.project_name}-app"
  compute_platform = "Server"
}

# Auto Scaling Groups for each environment
resource "aws_autoscaling_group" "asg" {
  for_each = toset(var.environments)

  name             = "${var.project_name}-${each.key}-asg"
  max_size         = 2
  min_size         = 1
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.launch_template[each.key].id
    version = "$Latest"
  }
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 120
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "ec2" {
  for_each = toset(var.environments)

  name        = "${var.project_name}-${each.key}-ec2-sg"
  description = "EC2 SG for ${each.key}"
  vpc_id      = var.vpc_id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "alb_to_ec2" {
  for_each = toset(var.environments)

  type      = "ingress"
  from_port = 5000
  to_port   = 5000
  protocol  = "tcp"

  security_group_id        = aws_security_group.ec2[each.key].id
  source_security_group_id = var.alb_security_group_ids[each.key]

  description = "Allow ALB to reach EC2 in ${each.key}"
}

resource "aws_launch_template" "launch_template" {
  for_each = toset(var.environments)

  name_prefix   = "${var.project_name}-${each.key}-lt"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = var.subnet_ids[0]
    security_groups = [
      aws_security_group.ec2[each.key].id
    ]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${each.key}-instance"
      Environment = each.key
    }
  }

  iam_instance_profile {
    name = var.ec2_inspector_instance_profile_name
  }
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -eux

    dnf update -y
    dnf install -y ruby wget

    cat <<EOT >/etc/myapp.env
    APP_ENV=${each.key}
    EOT

    chmod 644 /etc/myapp.env

    cd /home/ec2-user
    wget https://aws-codedeploy-${var.aws_region}.s3.${var.aws_region}.amazonaws.com/latest/install
    chmod +x install
    ./install auto

    systemctl daemon-reload
    systemctl enable codedeploy-agent
    systemctl start codedeploy-agent
  EOF
  )
}

# Deployment Groups for Blue/Green
resource "aws_codedeploy_deployment_group" "dg" {
  for_each = toset(var.environments)

  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "${var.project_name}-${each.key}-dg"
  service_role_arn      = var.codedeploy_role_arn

  autoscaling_groups = [
    aws_autoscaling_group.asg[each.key].name
  ]

  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 2
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  alarm_configuration {
  enabled = var.env_settings[each.key].rollback_enabled
  alarms  = var.env_settings[each.key].rollback_enabled ? [aws_cloudwatch_metric_alarm.app_unhealthy[each.key].alarm_name] : []
}


  load_balancer_info {
    target_group_info {
      name = var.target_group_blue[each.key]
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }
}

# CloudWatch alarms for application health (rollback triggers)
# These alarms monitor target group health and trigger CodeDeploy rollback
resource "aws_cloudwatch_metric_alarm" "app_unhealthy" {
  for_each = var.target_group_blue_arns

  alarm_name          = "${var.project_name}-${each.key}-app-unhealthy-alarm"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Maximum"
  threshold           = 0

  period              = 60
  evaluation_periods  = var.env_settings[each.key].alarm_eval_periods
  datapoints_to_alarm = 2

  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    TargetGroup  = split("/", each.value)[1]
    LoadBalancer = split("/", each.value)[0]
  }

  tags = {
    Environment = each.key
  }
}
