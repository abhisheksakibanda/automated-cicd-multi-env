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

resource "aws_iam_role_policy" "codebuild_cloudwatch_logs" {
  name = "${var.project_name}-codebuild-cloudwatch-logs"
  role = aws_iam_role.codebuild_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*:log-stream:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_s3_artifacts" {
  name = "${var.project_name}-codebuild-s3-artifacts"
  role = aws_iam_role.codebuild_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Bucket-level permissions
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.artifact_bucket_arn
      },

      # Object-level permissions
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = "${var.artifact_bucket_arn}/*"
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

# IAM role for EC2 instances to read AWS Inspector findings
resource "aws_iam_role" "ec2_inspector_role" {
  name = "${var.project_name}-ec2-inspector-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_inspector_policy" {
  name = "${var.project_name}-ec2-inspector-policy"
  role = aws_iam_role.ec2_inspector_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "inspector2:ListFindings",
          "inspector2:ListCoverage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_inspector_profile" {
  name = "${var.project_name}-ec2-inspector-profile"
  role = aws_iam_role.ec2_inspector_role.name
}
