variable "project_name" {}
variable "environments" {
  type = list(string)
}
variable "subnet_ids" {
  type = list(string)
}
variable "ami_id" {}
variable "codedeploy_role_arn" {}
variable "alarms" {
  type = list(string)
}
variable "target_group_blue" {
  type = map(string)
}
variable "target_group_green" {
  type = map(string)
}
variable "listener_arn" {}
