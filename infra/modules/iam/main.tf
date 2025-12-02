resource "aws_iam_role" "codebuild_service_role" {
  name = "${var.project_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_basic" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

resource "aws_iam_role" "codedeploy_service_role" {
  name = "${var.project_name}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_basic" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_role_policy_attachment" "codedeploy_cloudwatch" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# SNS Topic for CI/CD notifications (shared resource)
resource "aws_sns_topic" "cicd_notifications" {
  name = "${var.project_name}-cicd-notifications"
}

# IAM policy for CodeBuild to publish to SNS
resource "aws_iam_role_policy" "codebuild_sns_publish" {
  name = "${var.project_name}-codebuild-sns-publish"
  role = aws_iam_role.codebuild_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.cicd_notifications.arn
      }
    ]
  })
}

# IAM policy for CodeBuild to use AWS Inspector
resource "aws_iam_role_policy" "codebuild_inspector" {
  name = "${var.project_name}-codebuild-inspector"
  role = aws_iam_role.codebuild_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "inspector2:ListFindings",
          "inspector2:GetFindings",
          "inspector2:BatchGetCodeSnippet",
          "inspector2:ListCoverage",
          "inspector2:DescribeOrganizationConfiguration",
          "inspector2:GetConfiguration"
        ]
        Resource = "*"
      }
    ]
  })
}

# SNS topic policy to allow EventBridge to publish
resource "aws_sns_topic_policy" "eventbridge_publish" {
  arn = aws_sns_topic.cicd_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.cicd_notifications.arn
      }
    ]
  })
}