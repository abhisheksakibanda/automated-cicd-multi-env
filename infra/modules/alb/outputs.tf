output "listener_arns" {
  value = { for k, v in aws_lb_listener.listener : k => v.arn }
}

output "target_group_blue" {
  value = { for k, v in aws_lb_target_group.blue : k => v.arn }
}

output "target_group_green" {
  value = { for k, v in aws_lb_target_group.green : k => v.arn }
}

output "alb_dns" {
  value = { for k, v in aws_lb.this : k => v.dns_name }
}
