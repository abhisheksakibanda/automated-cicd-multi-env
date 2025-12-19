output "codebuild_role_arn" {
  value = aws_iam_role.codebuild_service_role.arn
}

output "codedeploy_role_arn" {
  value = aws_iam_role.codedeploy_service_role.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.cicd_notifications.arn
}

output "ec2_inspector_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_inspector_profile.name
}

output "ec2_inspector_role_arn" {
  value = aws_iam_role.ec2_inspector_role.arn
}
