resource "aws_s3_bucket" "artifact_bucket" {
  bucket        = "${var.project_name}-artifact-bucket"
  force_destroy = true
}

# Pipeline Role
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

resource "aws_iam_role_policy" "codepipeline_permissions" {
  name = "${var.project_name}-codepipeline_permissions"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow CodePipeline to use the CodeStar connection
      {
        Effect   = "Allow"
        Action   = "codestar-connections:UseConnection"
        Resource = aws_codestarconnections_connection.github_connection.arn
      },
      # Permissions for S3 artifact bucket
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.artifact_bucket.arn
      },
      # Permissions for objects within the S3 bucket
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.artifact_bucket.arn}/*"
      },
      # Permissions for CodeBuild
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = var.codebuild_project_arns
      },
      # Permissions for CodeDeploy
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:GetDeploymentConfig"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_codestarconnections_connection" "github_connection" {
  name          = "${var.project_name}-gh-conn"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "cicd_pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifact_bucket.bucket
  }

  # Stages
  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github_connection.arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = "dev"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "CodeBuild_Dev"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = var.codebuild_project_dev
      }
    }
  }

  # Test stage - runs integration tests in isolated environment
  stage {
    name = "Test"

    action {
      name             = "Integration_Test"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output", "build_output"]
      output_artifacts = ["test_output"]

      configuration = {
        ProjectName   = var.codebuild_test_project
        PrimarySource = "source_output"
      }
    }
  }

  # Deploy (dev) — integrates with CodeDeploy later in Task 4
  stage {
    name = "DeployToDev"

    action {
      name            = "Deploy_Dev"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = var.codedeploy_app
        DeploymentGroupName = var.codedeploy_group_dev
      }
    }
  }

  stage {
    name = "DeployToStaging"

    action {
      name            = "Deploy_Staging"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = var.codedeploy_app
        DeploymentGroupName = var.codedeploy_group_staging
      }
    }
  }

  # Approval before production
  stage {
    name = "ApprovalForProd"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "DeployToProd"

    action {
      name            = "Deploy_Prod"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = var.codedeploy_app
        DeploymentGroupName = var.codedeploy_group_prod
      }
    }
  }
}
