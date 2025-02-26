variable "cluster_name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "target_instances" { type = map(list(object({
  id         = string
  private_ip = string
}))) }
variable "dns_zone_id" { type = string }
variable "domain_name" { type = string }
variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for the load balancer listener"
}