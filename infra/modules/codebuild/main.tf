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

  # CloudWatch Logs configuration
  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = "/aws/codebuild/${var.project_name}-${each.key}-build"
    }
  }
}

# CloudWatch Events rule for build notifications
resource "aws_cloudwatch_event_rule" "build_events" {
  for_each = var.sns_topic_arn != "" ? toset(local.environments) : []

  name        = "${var.project_name}-${each.key}-build-events"
  description = "Capture CodeBuild events for ${each.key} environment"

  event_pattern = jsonencode({
    source      = ["aws.codebuild"]
    detail-type = ["CodeBuild Build State Change"]
    detail = {
      "build-status" = ["FAILED", "SUCCEEDED", "IN_PROGRESS"]
      "project-name" = [aws_codebuild_project.app_build[each.key].name]
    }
  })
}

# SNS target for build events
resource "aws_cloudwatch_event_target" "build_sns_target" {
  for_each = var.sns_topic_arn != "" ? toset(local.environments) : []

  rule      = aws_cloudwatch_event_rule.build_events[each.key].name
  target_id = "${var.project_name}-${each.key}-build-sns-target"
  arn       = var.sns_topic_arn
}

# Test CodeBuild project for integration testing
resource "aws_codebuild_project" "test_project" {
  name        = "${var.project_name}-test"
  description = "CodeBuild project for integration testing"
  service_role = var.codebuild_role_arn

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = var.test_buildspec_path
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  badge_enabled = true

  # CloudWatch Logs configuration
  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = "/aws/codebuild/${var.project_name}-test"
    }
  }
}

output "codebuild_project_names" {
  value = { for k, v in aws_codebuild_project.app_build : k => v.name }
}

output "test_project_name" {
  value = aws_codebuild_project.test_project.name
}
