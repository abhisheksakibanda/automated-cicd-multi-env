variable "project_name" {
  type        = string
  description = "Name of the project for which the pipeline is being created"
}
variable "github_owner" {
  type        = string
  description = "GitHub repository owner"
}
variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

variable "codebuild_project_dev" {
  type        = string
  description = "CodeBuild project for the development environment"
}
variable "codebuild_test_project" {
  type        = string
  description = "CodeBuild project for running integration tests"
}
variable "codedeploy_app" {
  type        = string
  description = "CodeDeploy application name"
}
variable "codedeploy_group_dev" {
  type        = string
  description = "CodeDeploy deployment group for the development environment"
}
variable "codedeploy_group_staging" {
  type        = string
  description = "CodeDeploy deployment group for the staging environment"
}
variable "codedeploy_group_prod" {
  type        = string
  description = "CodeDeploy deployment group for the production environment"
}
variable "codebuild_project_arns" {
  type        = list(string)
  description = "List of CodeBuild project ARNs that CodePipeline can trigger"
}
