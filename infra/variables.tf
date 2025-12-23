variable "project_name" {
  type    = string
  default = "automated-cicd-multi-env"
}

variable "github_token" {
  sensitive = true
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be deployed"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet IDs for ALB"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs for EC2 instances"
}

variable "alert_email_address" {
  type        = string
  description = "Email address to receive pipeline alerts"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID where resources will be deployed"
}

variable "aws_region" {
  type        = string
  description = "AWS region where resources will be created"
  default     = "us-east-1"
}
