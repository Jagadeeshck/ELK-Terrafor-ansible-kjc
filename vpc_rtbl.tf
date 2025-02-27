module "routable_vpc" {
  source      = "./modules/vpc_network"
  vpc_name    = "routable-vpc"
  cidr_block  = "10.0.0.0/16"
  is_routable = true
  aws_region  = var.aws_region
  az_count    = var.az_count
}