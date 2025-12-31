module "iam" {
  source              = "./modules/iam"
  project_name        = var.project_name
  aws_region          = var.aws_region
  artifact_bucket_arn = module.pipeline.artifact_bucket_arn
}

module "codebuild" {
  source             = "./modules/codebuild"
  project_name       = var.project_name
  environments       = ["dev", "staging", "prod"]
  codebuild_role_arn = module.iam.codebuild_role_arn
  buildspec_path     = "cicd/buildspecs/buildspec.yml"
  sns_topic_arn      = module.iam.sns_topic_arn
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

  aws_region   = var.aws_region
  project_name = var.project_name
  environments = ["dev", "staging", "prod"]

  vpc_id              = var.vpc_id
  subnet_ids          = var.private_subnets
  codedeploy_role_arn = module.iam.codedeploy_role_arn
  alb_security_group_ids = module.alb.alb_security_group_ids

  target_group_blue = module.alb.target_group_blue
  sns_topic_arn     = module.iam.sns_topic_arn

  ec2_inspector_instance_profile_name = module.iam.ec2_instance_profile_name
}

module "pipeline" {
  source = "./modules/pipeline"

  project_name = var.project_name

  github_owner = "abhisheksakibanda"
  github_repo  = "automated-cicd-multi-env"

  codebuild_project_dev  = module.codebuild.codebuild_project_names["dev"]
  codebuild_test_project = module.codebuild.test_project_name
  codebuild_project_arns = concat(
    module.codebuild.codebuild_project_arns,
    [module.codebuild.test_project_arn]
  )

  codedeploy_app           = module.codedeploy.codedeploy_app_name
  codedeploy_group_dev     = module.codedeploy.deployment_groups["dev"]
  codedeploy_group_staging = module.codedeploy.deployment_groups["staging"]
  codedeploy_group_prod    = module.codedeploy.deployment_groups["prod"]
}


module "monitoring" {
  source = "./modules/monitoring"

  project_name  = var.project_name
  pipeline_name = module.pipeline.pipeline_name
  aws_region    = var.aws_region

  codebuild_project_dev     = module.codebuild.codebuild_project_names["dev"]
  codebuild_project_staging = module.codebuild.codebuild_project_names["staging"]
  codebuild_project_prod    = module.codebuild.codebuild_project_names["prod"]

  codedeploy_app               = module.codedeploy.codedeploy_app_name
  codedeploy_deployment_groups = module.codedeploy.deployment_groups

  target_group_blue_arns  = module.alb.target_group_blue_arn
  target_group_green_arns = module.alb.target_group_green_arn

  sns_topic_arn    = module.iam.sns_topic_arn
  create_sns_topic = false
  alert_email      = var.alert_email_address
}

module "inspector" {
  source         = "./modules/security"
  aws_account_id = var.aws_account_id
}

