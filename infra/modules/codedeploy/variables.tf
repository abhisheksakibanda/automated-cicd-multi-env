variable "project_name" {
  type = string
}
variable "environments" {
  type = list(string)
}
variable "subnet_ids" {
  type = list(string)
}
variable "ami_id" {}
variable "codedeploy_role_arn" {}

variable "target_group_blue" {
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
