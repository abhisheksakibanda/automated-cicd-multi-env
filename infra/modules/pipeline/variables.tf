variable "project_name" {}
variable "github_owner" {}
variable "github_repo" {}
variable "github_token" {
  sensitive = true
}

variable "codebuild_project_dev" {}
variable "codedeploy_app" {}
variable "codedeploy_group_dev" {}
variable "codedeploy_group_staging" {}
variable "codedeploy_group_prod" {}
