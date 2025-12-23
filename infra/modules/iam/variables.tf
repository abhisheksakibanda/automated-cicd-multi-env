variable "project_name" {
  type        = string
  description = "Base name for the CI/CD project"
}

data "aws_caller_identity" "current" {}

variable "aws_region" {
  type        = string
  description = "AWS region where resources will be created"
}

