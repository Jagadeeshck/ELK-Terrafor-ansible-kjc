# Security group rule for cross-account access to Monitoring cluster LB
resource "aws_security_group_rule" "cross_account_monitoring" {
  count             = var.enable_cross_account ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = module.monitoring_lb.security_group_id
  cidr_blocks       = ["0.0.0.0/0"] # Replace with specific cross-account VPC CIDR if known
  description       = "Allow cross-account access to monitoring services"
}