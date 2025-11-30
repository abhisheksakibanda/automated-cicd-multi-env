locals {
  environments = var.environments
}

resource "aws_codebuild_project" "app_build" {
  for_each = toset(local.environments)

  name        = "${var.project_name}-${each.key}-build"
  description = "CodeBuild project for ${each.key} environment"
  service_role = var.codebuild_role_arn

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"

    environment_variable {
      name  = "APP_ENV"
      value = each.key
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec_path
  }

  artifacts {
    type = "CODEPIPELINE"
  }
  badge_enabled = true
}

output "codebuild_project_names" {
  value = [for k, v in aws_codebuild_project.app_build : v.name]
}
