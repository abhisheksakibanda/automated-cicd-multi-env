output "codebuild_role_arn" {
  value = aws_iam_role.codebuild_service_role.arn
}

output "codedeploy_role_arn" {
  value = aws_iam_role.codedeploy_service_role.arn
}