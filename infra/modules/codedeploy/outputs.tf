output "codedeploy_app_name" {
  value = aws_codedeploy_app.app.name
}

output "deployment_groups" {
  value = { for k, v in aws_codedeploy_deployment_group.dg : k => v.deployment_group_name }
}

output "app_unhealthy_alarm_names" {
  value = { for k, v in aws_cloudwatch_metric_alarm.app_unhealthy : k => v.alarm_name }
}