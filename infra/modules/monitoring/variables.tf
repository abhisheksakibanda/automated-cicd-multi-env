variable "project_name" {
  type        = string
  description = "Base name for the CI/CD project"
}
variable "pipeline_name" {
  type        = string
  description = "Name of the CodePipeline"
}
variable "aws_region" {
  type        = string
  description = "AWS region where resources will be created"
}

variable "codebuild_project_dev" {
  type        = string
  description = "CodeBuild project for the development environment"
}
variable "codebuild_project_staging" {
  type        = string
  description = "CodeBuild project for the staging environment"
}
variable "codebuild_project_prod" {
  type        = string
  description = "CodeBuild project for the production environment"
}

variable "codedeploy_app" {
  type        = string
  description = "CodeDeploy application name"
}

variable "alert_email" {
  type        = string
  description = "Email to receive pipeline alerts"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for notifications (shared resource)"
  default     = ""
}

variable "create_sns_topic" {
  type        = bool
  description = "Whether to create a new SNS topic (set to false if using shared topic)"
  default     = false
}

variable "target_group_blue_arns" {
  type        = map(string)
  description = "Map of blue target group ARNs by environment"
  default     = {}
}

variable "target_group_green_arns" {
  type        = map(string)
  description = "Map of green target group ARNs by environment"
  default     = {}
}

variable "codedeploy_deployment_groups" {
  type        = map(string)
  description = "Map of deployment groups by environment"
  default     = {}
}
