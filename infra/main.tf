module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

module "codebuild" {
  source            = "./modules/codebuild"
  project_name      = var.project_name
  environments      = ["dev", "staging", "prod"]
  codebuild_role_arn = module.iam.codebuild_role_arn
  buildspec_path    = "cicd/buildspecs/buildspec.yml"
  sns_topic_arn     = module.iam.sns_topic_arn
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

  target_group_blue  = module.alb.target_group_blue
  target_group_green = module.alb.target_group_green
  listener_arns      = module.alb.listener_arns
  sns_topic_arn      = module.iam.sns_topic_arn
}

module "pipeline" {
  source = "./modules/pipeline"

  project_name = var.project_name

  github_owner = "abhisheksakibanda"
  github_repo  = "automated-cicd-multi-env"
  github_token = var.github_token

  codebuild_project_dev  = module.codebuild.codebuild_project_names["dev"]
  codebuild_test_project = module.codebuild.test_project_name

  codedeploy_app           = module.codedeploy.codedeploy_app_name
  codedeploy_group_dev     = module.codedeploy.deployment_groups["dev"]
  codedeploy_group_staging = module.codedeploy.deployment_groups["staging"]
  codedeploy_group_prod    = module.codedeploy.deployment_groups["prod"]
}


module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  pipeline_name = module.pipeline.pipeline_name
  aws_region = "us-east-1"

  codebuild_project_dev     = module.codebuild.codebuild_project_names["dev"]
  codebuild_project_staging = module.codebuild.codebuild_project_names["staging"]
  codebuild_project_prod    = module.codebuild.codebuild_project_names["prod"]

  codedeploy_app = module.codedeploy.codedeploy_app_name
  codedeploy_deployment_groups = module.codedeploy.deployment_groups

  target_group_blue_arns  = module.alb.target_group_blue_arn
  target_group_green_arns = module.alb.target_group_green_arn

  sns_topic_arn = module.iam.sns_topic_arn
  alert_email   = var.alert_email_address
}

