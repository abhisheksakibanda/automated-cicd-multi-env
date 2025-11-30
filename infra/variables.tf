variable "project_name" {
  type    = string
  default = "automated-cicd-multi-env"
}

variable "github_token" {
  sensitive = true
}