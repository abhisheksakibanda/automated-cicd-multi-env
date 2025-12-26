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
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = "ELB"
  health_check_grace_period = 120
}

resource "aws_launch_template" "launch_template" {
  for_each = toset(var.environments)

  name_prefix   = "${var.project_name}-${each.key}-lt"
  image_id      = var.ami_id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = var.subnet_ids[0]
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
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  alarm_configuration {
    enabled = each.key == "prod"
    alarms  = each.key == "prod" ? [aws_cloudwatch_metric_alarm.app_unhealthy[each.key].alarm_name] : []
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
  for_each = toset(var.environments)

  alarm_name          = "${var.project_name}-${each.key}-app-unhealthy-alarm"
  alarm_description   = "Triggers rollback if app stays unhealthy after startup"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Maximum"
  threshold           = 0

  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2

  treat_missing_data = "notBreaching"

  dimensions = {
    TargetGroup = var.target_group_blue[each.key]
  }

  alarm_actions = each.key == "prod" ? [var.sns_topic_arn] : []

  tags = {
    Environment = each.key
    Purpose     = "CodeDeployRollback"
  }
}

