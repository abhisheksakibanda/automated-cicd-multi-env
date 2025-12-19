output "codebuild_project_names" {
  value = { for k, v in aws_codebuild_project.app_build : k => v.name }
}

output "test_project_name" {
  value = aws_codebuild_project.test_project.name
}
