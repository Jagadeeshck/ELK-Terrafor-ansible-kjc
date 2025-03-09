data "aws_route53_zone" "main" {
  count       = var.domain_name != "" ? 1 : 0
  name        = "${var.domain_name}."
  private_zone = false
}