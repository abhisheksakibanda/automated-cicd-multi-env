variable "project_name" {
  type = string
}

variable "environments" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}
