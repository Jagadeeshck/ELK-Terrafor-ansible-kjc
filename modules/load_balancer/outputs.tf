output "lb_endpoints" {
  value = { for role, lb in aws_lb.role_lb : role => lb.dns_name }
}

output "security_group_id" {
  value = aws_security_group.lb.id
}