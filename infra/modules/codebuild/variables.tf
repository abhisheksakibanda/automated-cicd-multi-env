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
  default = "buildspec.yml"
}
