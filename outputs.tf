output "business_cluster_endpoints" {
  value = { for k, v in module.business_lb : k => v.lb_endpoints }
}

output "monitoring_cluster_endpoints" {
  value = module.monitoring_lb.lb_endpoints
}

output "cross_account_role_arn" {
  value = var.enable_cross_account ? aws_iam_role.cross_account_monitoring[0].arn : null
}