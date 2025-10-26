output "security_group" {
  value = aws_security_group.default.id
}

output "asg_name" {
  value = aws_autoscaling_group.web-asg.id
}

output "lb_name" {
  value = module.nlb.dns_name
}
