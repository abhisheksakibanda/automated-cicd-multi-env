resource "aws_codedeploy_app" "app" {
  name = "${var.project_name}-app"
  compute_platform = "Server"
}

# Auto Scaling Groups for each environment
resource "aws_autoscaling_group" "asg" {
  for_each = toset(var.environments)

  name                      = "${var.project_name}-${each.key}-asg"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1

  launch_configuration      = aws_launch_configuration.launch_config[each.key].name
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "EC2"
}

resource "aws_launch_configuration" "launch_config" {
  for_each = toset(var.environments)

  name_prefix   = "${var.project_name}-${each.key}-lc"
  image_id      = var.ami_id
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
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
    deployment_type = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }
  }

  alarm_configuration {
    enabled = true
    alarms = var.alarms
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = var.target_group_blue[each.key]
      }
      target_group {
        name = var.target_group_green[each.key]
      }
      prod_traffic_route {
        listener_arns = [var.listener_arn]
      }
      test_traffic_route {
        listener_arns = [var.listener_arn]
      }
    }
  }
}
