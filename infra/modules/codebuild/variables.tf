variable "project_name" {
  type = string
}

variable "environments" {
  type = list(string)
}

variable "codebuild_role_arn" {
  type = string
}

variable "buildspec_path" {
  type    = string
  default = "cicd/buildspecs/buildspec.yml"
}

variable "test_buildspec_path" {
  type    = string
  default = "cicd/buildspecs/test-buildspec.yml"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for build notifications"
  default     = ""
}
