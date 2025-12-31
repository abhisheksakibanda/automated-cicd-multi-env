variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "alb_security_group_ids" {
    type = map(string)
}

variable "project_name" {
  type = string
}
variable "environments" {
  type = list(string)
}
variable "subnet_ids" {
  type = list(string)
}

variable "codedeploy_role_arn" {}

variable "target_group_blue" {
  type = map(string)
}

variable "target_group_blue_arns" {
  type = map(string)
}


variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for alarm notifications"
  default     = ""
}

variable "ec2_inspector_instance_profile_name" {
  type        = string
  description = "EC2 Inspector Instance Profile Name"
}

variable "env_settings" {
  description = "Environment-specific deployment and alarm behavior"
  type = map(object({
    rollback_enabled     = bool
    alarm_eval_periods   = number
  }))
}
