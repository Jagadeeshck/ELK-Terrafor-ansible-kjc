module "business_clusters" {
  for_each = var.business_clusters
  
  source = "./modules/elasticsearch_nodes"
  
  cluster_name        = each.key
  vpc_id              = module.non_routable_vpc.vpc_id
  subnet_ids          = module.non_routable_vpc.private_subnet_ids
  cluster_type        = "business"
  node_configs        = each.value.node_configs
  enable_monitoring   = each.value.enable_monitoring
  monitoring_endpoint = module.monitoring_cluster.fleet_endpoint
  aws_region          = var.aws_region
  az_count            = var.az_count
  az_mappings         = each.value.az_mappings
  iam_instance_profile = aws_iam_instance_profile.es_s3_profile.name
  snapshot_bucket      = aws_s3_bucket.snapshots[each.key].bucket
  os_type             = each.value.os_type
  root_volume_size    = each.value.root_volume_size
  data_volume_size    = each.value.data_volume_size
  elasticsearch_version = var.elasticsearch_version
}

module "monitoring_cluster" {
  source = "./modules/elasticsearch_nodes"
  
  cluster_name        = "monitoring-cluster"
  vpc_id              = module.non_routable_vpc.vpc_id
  subnet_ids          = module.non_routable_vpc.private_subnet_ids
  cluster_type        = "monitoring"
  node_configs        = var.monitoring_config.node_configs
  enable_monitoring   = true
  aws_region          = var.aws_region
  az_count            = var.az_count
  az_mappings         = var.monitoring_config.az_mappings
  iam_instance_profile = aws_iam_instance_profile.es_s3_profile.name
  snapshot_bucket      = aws_s3_bucket.snapshots["monitoring-cluster"].bucket
  os_type             = var.monitoring_config.os_type
  root_volume_size    = var.monitoring_config.root_volume_size
  data_volume_size    = var.monitoring_config.data_volume_size
  elasticsearch_version = var.elasticsearch_version
}