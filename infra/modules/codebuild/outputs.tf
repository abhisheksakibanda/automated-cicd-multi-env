output "codebuild_project_names" {
  value = { for k, v in aws_codebuild_project.app_build : k => v.name }
}

output "codebuild_project_arns" {
  description = "ARNs of per-environment CodeBuild projects"
  value       = values(aws_codebuild_project.app_build)[*].arn
}

output "test_project_name" {
  value = aws_codebuild_project.test_project.name
}

output "test_project_arn" {
  description = "ARN of the integration test CodeBuild project"
  value       = aws_codebuild_project.test_project.arn
}
