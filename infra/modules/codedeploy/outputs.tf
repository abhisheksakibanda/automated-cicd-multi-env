output "codedeploy_app_name" {
  value = aws_codedeploy_app.app.name
}

output "deployment_groups" {
  value = { for k, v in aws_codedeploy_deployment_group.dg : k => v.deployment_group_name }
}
