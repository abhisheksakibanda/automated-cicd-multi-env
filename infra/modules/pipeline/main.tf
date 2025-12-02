resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "${var.project_name}-artifact-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.artifact_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
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
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipelineFullAccess"
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
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = "dev"
        OAuthToken = var.github_token
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
        ProjectName = var.codebuild_test_project
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

  # Manual approval before staging
  stage {
    name = "ApprovalForStaging"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
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
