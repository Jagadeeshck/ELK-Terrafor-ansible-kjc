data "aws_route53_zone" "main" {
  name         = "kjc.infotech.net."
  private_zone = false
}