resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "${var.project_name}-cicd-dashboard"

  dashboard_body = jsonencode({
    widgets = [

      # ============================
      # Pipeline execution & lead time
      # ============================
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 24,
        "height" : 6,
        "properties" : {
          "title" : "Pipeline Execution Health & Lead Time",
          "metrics" : [
            ["AWS/CodePipeline", "PipelineDuration", "Pipeline", var.pipeline_name, { "stat" : "Average", "label" : "Avg Duration (sec)" }],
            [".", "FailedPipelineExecutions", ".", ".", { "stat" : "Sum", "label" : "Failures" }]
          ],
          "view" : "timeSeries",
          "region" : var.aws_region
        }
      },

      # ============================
      # Build performance
      # ============================
      {
        "type" : "metric",
        "x" : 0,
        "y" : 7,
        "width" : 24,
        "height" : 6,
        "properties" : {
          "title" : "CodeBuild Mean Build Duration",
          "metrics" : [
            ["AWS/CodeBuild", "Duration", "ProjectName", var.codebuild_project_dev, { "stat" : "Average", "label" : "Dev" }],
            [".", "Duration", ".", var.codebuild_project_staging, { "stat" : "Average", "label" : "Staging" }],
            [".", "Duration", ".", var.codebuild_project_prod, { "stat" : "Average", "label" : "Prod" }]
          ],
          "view" : "timeSeries",
          "region" : var.aws_region
        }
      },

      # ============================
      # Deployment success via ALB
      # ============================
      {
        "type" : "metric",
        "x" : 0,
        "y" : 14,
        "width" : 24,
        "height" : 6,
        "properties" : {
          "title" : "Deployment Health (ALB Target Groups)",
          "metrics" : [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", var.target_group_metric_names["dev"], "LoadBalancer", var.alb_metric_names["dev"], { "stat" : "Maximum", "label" : "Dev Unhealthy Hosts" }],
            [".", "UnHealthyHostCount", "TargetGroup", var.target_group_metric_names["staging"], "LoadBalancer", var.alb_metric_names["staging"], { "stat" : "Maximum", "label" : "Staging Unhealthy Hosts" }],
            [".", "UnHealthyHostCount", "TargetGroup", var.target_group_metric_names["prod"], "LoadBalancer", var.alb_metric_names["prod"], { "stat" : "Maximum", "label" : "Prod Unhealthy Hosts" }]
          ],
          "view" : "timeSeries",
          "region" : var.aws_region
        }
      },

      # ============================
      # HTTP 5XX (deployment failures)
      # ============================
      {
        "type" : "metric",
        "x" : 0,
        "y" : 21,
        "width" : 24,
        "height" : 6,
        "properties" : {
          "title" : "Application 5XX Errors",
          "metrics" : [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "TargetGroup", var.target_group_metric_names["dev"], "LoadBalancer", var.alb_metric_names["dev"], { "stat" : "Sum", "label" : "Dev 5XX" }],
            [".", "HTTPCode_Target_5XX_Count", "TargetGroup", var.target_group_metric_names["staging"], "LoadBalancer", var.alb_metric_names["staging"], { "stat" : "Sum", "label" : "Staging 5XX" }],
            [".", "HTTPCode_Target_5XX_Count", "TargetGroup", var.target_group_metric_names["prod"], "LoadBalancer", var.alb_metric_names["prod"], { "stat" : "Sum", "label" : "Prod 5XX" }]
          ],
          "view" : "timeSeries",
          "region" : var.aws_region
        }
      },

      # ============================
      # Log-based failure analysis
      # ============================
      {
        "type" : "log",
        "x" : 0,
        "y" : 28,
        "width" : 24,
        "height" : 6,
        "properties" : {
          "region" : var.aws_region,
          "title" : "Recent Build & Test Errors",
          "query" : "SOURCE '/aws/codebuild/${var.codebuild_project_dev}' | SOURCE '/aws/codebuild/${var.codebuild_test_project}' | fields @timestamp, @message | filter @message like /ERROR/ or @message like /FAIL/ or @message like /Exception/ | sort @timestamp desc | limit 20"
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
