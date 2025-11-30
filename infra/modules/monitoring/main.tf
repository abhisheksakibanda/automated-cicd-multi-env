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
            [ "AWS/CodePipeline", "SuccessfulExecutions", "PipelineName", var.pipeline_name ],
            [ ".", "FailedExecutions", ".", ".", { "stat": "Sum", "id": "fail" } ]
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
            [ "AWS/CodeBuild", "Duration", "ProjectName", var.codebuild_project_dev ],
            [ ".", "Duration", ".", var.codebuild_project_staging ],
            [ ".", "Duration", ".", var.codebuild_project_prod ]
          ],
          "view" : "timeSeries",
          "region" : var.aws_region
        }
      },

      # Deployment Success Rate (CodeDeploy)
      {
        "type": "metric",
        "x": 0,
        "y": 14,
        "width": 12,
        "height": 6,
        "properties": {
          "title": "Deployment Success Rate",
          "metrics": [
            [ "AWS/CodeDeploy", "DeploymentSuccessCount", "ApplicationName", var.codedeploy_app ],
            [ ".", "DeploymentFailureCount", ".", ".", { "id": "failure" } ]
          ],
          "view": "timeSeries",
          "region": var.aws_region
        }
      },
      {
        "type": "log",
        "x": 0,
        "y": 21,
        "width": 12,
        "height": 6,
        "properties": {
          "query": "fields @timestamp, @message | filter @message like /error/ or /fail/ | sort @timestamp desc | limit 20",
          "region": "us-east-1",
          "title": "Recent Deployment Errors"
        }
      }
    ]
  })
}

resource "aws_sns_topic" "cicd_alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.cicd_alerts.arn
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
  alarm_actions       = [aws_sns_topic.cicd_alerts.arn]

  dimensions = {
    PipelineName = var.pipeline_name
  }
}
