module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

module "codebuild" {
  source            = "./modules/codebuild"
  project_name      = var.project_name
  environments      = ["dev", "staging", "prod"]
  codebuild_role_arn = module.iam.codebuild_role_arn
}

module "pipeline" {
  source = "./modules/pipeline"

  project_name = var.project_name

  github_owner = "YOUR_GITHUB_USERNAME"
  github_repo  = "automated-cicd-multi-env"
  github_token = var.github_token

  codebuild_project_dev = "automated-cicd-multi-env-dev-build"

  codedeploy_app           = "your-app-name"
  codedeploy_group_dev     = "dev-group"
  codedeploy_group_staging = "staging-group"
  codedeploy_group_prod    = "prod-group"
}

module "alb" {
  source = "./modules/alb"

  project_name = var.project_name
  environments = ["dev", "staging", "prod"]

  vpc_id         = var.vpc_id
  public_subnets = var.public_subnets
}

module "codedeploy" {
  source = "./modules/codedeploy"

  project_name        = var.project_name
  environments        = ["dev", "staging", "prod"]

  subnet_ids         = var.private_subnets
  ami_id             = "ami-0c02fb55956c7d316"
  codedeploy_role_arn = module.iam.codedeploy_role_arn

  alarms = ["app-unhealthy-alarm"]

  target_group_blue  = module.alb.target_group_blue
  target_group_green = module.alb.target_group_green
  listener_arn       = module.alb.listener_arns
}


module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  pipeline_name = module.pipeline.pipeline_name
  aws_region = "us-east-1"

  codebuild_project_dev = "automated-cicd-multi-env-dev-build"
  codebuild_project_staging = "automated-cicd-multi-env-staging-build"
  codebuild_project_prod = "automated-cicd-multi-env-prod-build"

  codedeploy_app = module.codedeploy.codedeploy_app_name

  alert_email = "your-email@example.com"
}

