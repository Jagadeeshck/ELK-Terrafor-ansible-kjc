module "non_routable_vpc" {
  source       = "./modules/vpc_network"
  vpc_name     = "non-routable-vpc"
  cidr_block   = "10.1.0.0/16"
  is_routable  = false
  aws_region   = var.aws_region
  az_count     = var.az_count
}

resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id        = module.routable_vpc.vpc_id
  peer_vpc_id   = module.non_routable_vpc.vpc_id
  auto_accept   = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.non_routable_vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.non_routable_vpc.route_table_ids
}

resource "aws_vpc_endpoint" "es" {
  vpc_id              = module.non_routable_vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.es"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.non_routable_vpc.private_subnet_ids
  security_group_ids  = [module.monitoring_cluster.security_group_id] # Use monitoring_cluster's SG
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = module.non_routable_vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.non_routable_vpc.private_subnet_ids
  security_group_ids  = [module.monitoring_cluster.security_group_id] # Use monitoring_cluster's SG
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.non_routable_vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.non_routable_vpc.private_subnet_ids
  security_group_ids  = [module.monitoring_cluster.security_group_id] # Use monitoring_cluster's SG
  private_dns_enabled = true
}