# S3 Buckets for Binaries and Snapshots
resource "aws_s3_bucket" "binaries" {
  bucket = "kjc-elasticsearch-binaries-${var.aws_region}"
}

resource "aws_s3_bucket_acl" "binaries" {
  bucket = aws_s3_bucket.binaries.id
  acl    = "private"
}

resource "aws_s3_bucket" "snapshots" {
  for_each = merge(var.business_clusters, { "monitoring-cluster" = var.monitoring_config })
  bucket   = "kjc-es-snapshots-${each.key}-${var.aws_region}"
}

resource "aws_s3_bucket_acl" "snapshots" {
  for_each = aws_s3_bucket.snapshots
  bucket   = each.value.id
  acl      = "private"
}



# IAM Role for S3 Access
resource "aws_iam_role" "es_s3_role" {
  name = "es-s3-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "es_s3_policy" {
  name = "es-s3-access-policy"
  role = aws_iam_role.es_s3_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.binaries.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        Resource = [for bucket in aws_s3_bucket.snapshots : "${bucket.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "es_s3_profile" {
  name = "es-s3-profile"
  role = aws_iam_role.es_s3_role.name
}

# Cross-Account IAM Role for Monitoring Cluster
resource "aws_iam_role" "cross_account_monitoring" {
  count = var.enable_cross_account ? 1 : 0
  name  = "cross-account-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.cross_account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cross_account_policy" {
  count = var.enable_cross_account ? 1 : 0
  name  = "cross-account-monitoring-policy"
  role  = aws_iam_role.cross_account_monitoring[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:ESHttp*",
          "elastic-agent:Fleet*",
          "apm:*",
          "logstash:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Business Clusters
module "business_clusters" {
  for_each = var.business_clusters

  source = "./modules/elasticsearch_nodes"

  cluster_name          = each.key
  vpc_id                = module.non_routable_vpc.vpc_id
  subnet_ids            = module.non_routable_vpc.private_subnet_ids
  cluster_type          = "business"
  node_configs          = each.value.node_configs
  enable_monitoring     = each.value.enable_monitoring
  monitoring_endpoint   = module.monitoring_cluster.fleet_endpoint
  aws_region            = var.aws_region
  az_count              = var.az_count
  az_mappings           = each.value.az_mappings
  iam_instance_profile  = aws_iam_instance_profile.es_s3_profile.name
  snapshot_bucket       = aws_s3_bucket.snapshots[each.key].bucket
  os_type               = each.value.os_type
  elasticsearch_version = var.elasticsearch_version
}

# Monitoring Cluster
# Monitoring Cluster
module "monitoring_cluster" {
  source = "./modules/elasticsearch_nodes"

  cluster_name          = "monitoring-cluster"
  vpc_id                = module.non_routable_vpc.vpc_id
  subnet_ids            = module.non_routable_vpc.private_subnet_ids
  cluster_type          = "monitoring"
  node_configs          = var.monitoring_config.node_configs
  enable_monitoring     = true
  monitoring_endpoint   = "" # Explicitly set to empty string for clarity
  aws_region            = var.aws_region
  az_count              = var.az_count
  az_mappings           = var.monitoring_config.az_mappings
  iam_instance_profile  = aws_iam_instance_profile.es_s3_profile.name
  snapshot_bucket       = aws_s3_bucket.snapshots["monitoring-cluster"].bucket
  os_type               = var.monitoring_config.os_type
  elasticsearch_version = var.elasticsearch_version
}

# Load Balancers
# Business Clusters Load Balancers
module "business_lb" {
  for_each = { for cluster_name, cluster in module.business_clusters : cluster_name => cluster.instances }

  source = "./modules/load_balancer"

  cluster_name     = each.key
  vpc_id           = module.routable_vpc.vpc_id
  subnet_ids       = module.routable_vpc.public_subnet_ids
  target_instances = { for role, instances in each.value : role => instances if length(instances) > 1 }
  dns_zone_id      = data.aws_route53_zone.main.zone_id
  domain_name      = "kjc.infotech.net"
  certificate_arn  = var.certificate_arn
}

# Monitoring Cluster Load Balancer
module "monitoring_lb" {
  source = "./modules/load_balancer"

  cluster_name     = "monitoring-cluster"
  vpc_id           = module.routable_vpc.vpc_id
  subnet_ids       = module.routable_vpc.public_subnet_ids
  target_instances = { for role, instances in module.monitoring_cluster.instances : role => instances if length(instances) > 1 }
  dns_zone_id      = data.aws_route53_zone.main.zone_id
  domain_name      = "kjc.infotech.net"
  certificate_arn  = var.certificate_arn
}

# Ansible Configuration
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory/hosts.yml"
  content = templatefile("${path.module}/templates/hosts.yml.tmpl", {
    business_clusters  = module.business_clusters
    monitoring_cluster = module.monitoring_cluster
    business_lbs       = module.business_lb
    monitoring_lb      = module.monitoring_lb
    s3_binaries_bucket = aws_s3_bucket.binaries.bucket
  })
}

resource "local_file" "ansible_site" {
  filename = "${path.module}/ansible/site.yml"
  content  = <<EOF
---
- name: Configure Common Setup
  hosts: all
  become: true
  roles:
    - common

- name: Configure Master Nodes
  hosts: all:&role_master
  become: true
  roles:
    - master_node
    - { role: elastic_agent, when: "enable_monitoring | default(false)" }

- name: Configure Data Nodes
  hosts: all:&role_data
  become: true
  roles:
    - data_node
    - { role: elastic_agent, when: "enable_monitoring | default(false)" }

- name: Configure Kibana Nodes
  hosts: all:&role_kibana
  become: true
  roles:
    - kibana_node
    - { role: elastic_agent, when: "enable_monitoring | default(false)" }

- name: Configure ML Nodes
  hosts: all:&role_ml
  become: true
  roles:
    - ml_node
    - { role: elastic_agent, when: "enable_monitoring | default(false)" }

- name: Configure Fleet Nodes
  hosts: all:&role_fleet
  become: true
  roles:
    - fleet_node
    - elastic_agent

- name: Configure APM Nodes
  hosts: all:&role_apm
  become: true
  roles:
    - apm_node
    - elastic_agent

- name: Configure Logstash Nodes
  hosts: all:&role_logstash
  become: true
  roles:
    - logstash_node
    - elastic_agent
EOF
}

resource "null_resource" "ansible_provision" {
  depends_on = [
    module.business_clusters,
    module.monitoring_cluster,
    local_file.ansible_inventory,
    local_file.ansible_site
  ]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/ansible/inventory/hosts.yml ${path.module}/ansible/site.yml"
  }

  triggers = {
    inventory = local_file.ansible_inventory.id
    site      = local_file.ansible_site.id
  }
}