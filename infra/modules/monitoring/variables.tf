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

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for notifications (shared resource)"
  default     = ""
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