output "listener_arns" {
  value = { for k, v in aws_lb_listener.listener : k => v.arn }
}

output "target_group_blue" {
  value = { for k, v in aws_lb_target_group.blue : k => v.name }
}

output "target_group_green" {
  value = { for k, v in aws_lb_target_group.green : k => v.name }
}

# Also output ARNs in case needed elsewhere
output "target_group_blue_arn" {
  value = { for k, v in aws_lb_target_group.blue : k => v.arn }
}

output "target_group_green_arn" {
  value = { for k, v in aws_lb_target_group.green : k => v.arn }
}

output "alb_dns" {
  value = { for k, v in aws_lb.this : k => v.dns_name }
}

output "alb_security_group_ids" {
  value = { for k, v in aws_security_group.alb_sg : k => v.id }
}

data "aws_caller_identity" "current" {}

output "alb_metric_names" {
  value = {
    for k, v in aws_lb.this :
    k => replace(
      v.arn,
      "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/",
      ""
    )
  }
}

output "target_group_metric_names" {
  value = {
    for k, v in aws_lb_target_group.blue :
    k => replace(
      v.arn,
      "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:targetgroup/",
      ""
    )
  }
}
