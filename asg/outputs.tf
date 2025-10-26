output "security_group" {
  value = module.nlb.security_group_id
}

output "asg_name" {
  value = aws_autoscaling_group.web-asg.id
}

output "lb_name" {
  value = module.nlb.dns_name
}
