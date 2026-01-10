resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "${var.project_name}-cicd-dashboard"

  dashboard_body = jsonencode({
    widgets = [

      # CodePipeline Success Rate
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "title" : "Pipeline Execution Success Rate",
          "metrics" : [
            ["AWS/CodePipeline", "SuccessfulExecutions", "PipelineName", var.pipeline_name],
            [".", "FailedExecutions", ".", ".", { "stat" : "Sum", "id" : "fail" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : var.aws_region
        }
      },

      # CodeBuild Build Duration
      {
        "type" : "metric",
        "x" : 0,
        "y" : 7,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "title" : "Mean Build Duration",
          "metrics" : [
            ["AWS/CodeBuild", "Duration", "ProjectName", var.codebuild_project_dev, { "stat" : "Average", "label" : "Dev" }],
            [".", "Duration", ".", var.codebuild_project_staging, { "stat" : "Average", "label" : "Staging" }],
            [".", "Duration", ".", var.codebuild_project_prod, { "stat" : "Average", "label" : "Prod" }]
          ],
          "view" : "timeSeries",
          "region" : var.aws_region
        }
      },

      # Mean Time to Deployment (CodeDeploy)
      {
        "type" : "metric",
        "x" : 12,
        "y" : 7,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "title" : "Mean Time to Deployment (seconds)",
          "metrics" : [
            ["AWS/CodeDeploy", "DeploymentDuration", "ApplicationName", var.codedeploy_app, "DeploymentGroupName", var.codedeploy_deployment_groups["dev"], { "stat" : "Average", "label" : "Dev" }],
            [".", ".", ".", ".", ".", var.codedeploy_deployment_groups["staging"], { "stat" : "Average", "label" : "Staging" }],
            [".", ".", ".", ".", ".", var.codedeploy_deployment_groups["prod"], { "stat" : "Average", "label" : "Prod" }]
          ],
          "view" : "timeSeries",
          "region" : var.aws_region,
          "yAxis" : {
            "left" : {
              "label" : "Duration (seconds)"
            }
          }
        }
      },

      # Deployment Success Rate (CodeDeploy)
      {
        "type" : "metric",
        "x" : 0,
        "y" : 14,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "title" : "Deployment Success Rate",
          "metrics" : [
            ["AWS/CodeDeploy", "DeploymentSuccessCount", "ApplicationName", var.codedeploy_app],
            [".", "DeploymentFailureCount", ".", ".", { "id" : "failure" }]
          ],
          "view" : "timeSeries",
          "region" : var.aws_region
        }
      },
      {
        "type" : "log",
        "x" : 0,
        "y" : 21,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : "us-east-1",
          "title" : "Recent Deployment Errors",
          "logGroupNames" : var.all_codebuild_log_groups,
          "query" : "fields @timestamp, @message | filter @message like /ERROR/ or @message like /FAIL/ or @message like /Exception/ | sort @timestamp desc | limit 20"
        }
      }
    ]
  })
}

# CodeBuild failure alarms for each environment
resource "aws_cloudwatch_metric_alarm" "codebuild_fail_alarm" {
  for_each = {
    dev     = var.codebuild_project_dev
    staging = var.codebuild_project_staging
    prod    = var.codebuild_project_prod
  }

  alarm_name          = "${var.project_name}-${each.key}-build-fail-alarm"
  alarm_description   = "Alerts when ${each.key} CodeBuild project fails"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedBuilds"
  namespace           = "AWS/CodeBuild"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [local.sns_topic_arn]

  dimensions = {
    ProjectName = each.value
  }
}


# HTTP 5xx error alarm for application health
resource "aws_cloudwatch_metric_alarm" "app_5xx_alarm" {
  for_each = var.target_group_blue_arns

  alarm_name          = "${var.project_name}-${each.key}-app-5xx-alarm"
  alarm_description   = "Triggers rollback if ${each.key} application has high 5xx error rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = [local.sns_topic_arn]

  dimensions = {
    TargetGroup  = split("/", each.value)[1]
    LoadBalancer = split("/", each.value)[0]
  }

  tags = {
    Environment = each.key
    Purpose     = "CodeDeployRollback"
  }
}

# Use shared SNS topic if provided, otherwise create one
# Note: We use a separate variable to determine if we should create the topic
# to avoid issues with unknown values at plan time
resource "aws_sns_topic" "cicd_alerts" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.project_name}-alerts"
}

locals {
  sns_topic_arn = var.create_sns_topic ? (length(aws_sns_topic.cicd_alerts) > 0 ? aws_sns_topic.cicd_alerts[0].arn : "") : var.sns_topic_arn
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = local.sns_topic_arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "pipeline_fail_alarm" {
  alarm_name          = "${var.project_name}-pipeline-fail-alarm"
  alarm_description   = "Alerts when pipeline fails"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedExecutions"
  namespace           = "AWS/CodePipeline"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [local.sns_topic_arn]

  dimensions = {
    PipelineName = var.pipeline_name
  }
}
