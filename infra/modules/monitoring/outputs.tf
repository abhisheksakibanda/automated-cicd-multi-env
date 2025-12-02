output "app_unhealthy_alarm_names" {
  value = { for k, v in aws_cloudwatch_metric_alarm.app_unhealthy_alarm : k => v.alarm_name }
}
