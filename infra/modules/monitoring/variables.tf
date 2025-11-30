variable "project_name" {}
variable "pipeline_name" {}
variable "aws_region" {}

variable "codebuild_project_dev" {}
variable "codebuild_project_staging" {}
variable "codebuild_project_prod" {}

variable "codedeploy_app" {}

variable "alert_email" {
  description = "Email to receive pipeline alerts"
}
