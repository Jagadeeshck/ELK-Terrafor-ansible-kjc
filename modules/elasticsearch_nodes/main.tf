resource "aws_security_group" "es_nodes" {
  vpc_id = var.vpc_id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16", "10.1.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  node_types = var.cluster_type == "business" ? {
    "master" = { config = var.node_configs.master_nodes, azs = var.az_mappings.master_nodes }
    "data"   = { config = var.node_configs.data_nodes, azs = var.az_mappings.data_nodes }
    "kibana" = { config = var.node_configs.kibana_nodes, azs = var.az_mappings.kibana_nodes }
    "ml"     = { config = var.node_configs.ml_nodes, azs = var.az_mappings.ml_nodes }
  } : {
    "master"   = { config = var.node_configs.master_nodes, azs = var.az_mappings.master_nodes }
    "data"     = { config = var.node_configs.data_nodes, azs = var.az_mappings.data_nodes }
    "kibana"   = { config = var.node_configs.kibana_nodes, azs = var.az_mappings.kibana_nodes }
    "logstash" = { config = var.node_configs.logstash_nodes, azs = var.az_mappings.logstash_nodes }
    "apm"      = { config = var.node_configs.apm_nodes, azs = var.az_mappings.apm_nodes }
    "fleet"    = { config = var.node_configs.fleet_nodes, azs = var.az_mappings.fleet_nodes }
    "ml"       = { config = var.node_configs.ml_nodes, azs = var.az_mappings.ml_nodes }
  }
  amis = {
    "centos"        = "ami-centos-7-latest" # Replace with actual AMI ID
    "rhel"          = "ami-rhel-8-latest"   # Replace with actual AMI ID
    "amazon-linux"  = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  }
}

resource "aws_ebs_volume" "elastic_install" {
  for_each = { for role, config in local.node_types : role => config.config.count }
  count    = each.value
  
  availability_zone = local.node_types[each.key].azs[count.index % length(local.node_types[each.key].azs)]
  size              = 50
  type              = "gp3"
}

resource "aws_ebs_volume" "elastic_logs" {
  for_each = { for role, config in local.node_types : role => config.config.count }
  count    = each.value
  
  availability_zone = local.node_types[each.key].azs[count.index % length(local.node_types[each.key].azs)]
  size              = 50
  type              = "gp3"
}

resource "aws_ebs_volume" "elastic_data" {
  for_each = { for role, config in local.node_types : role => config.config.count if !contains(["i3", "c5d", "m5d"], split(".", local.node_types[each.key].config.instance_type)[0]) }
  count    = each.value
  
  availability_zone = local.node_types[each.key].azs[count.index % length(local.node_types[each.key].azs)]
  size              = var.data_volume_size
  type              = "gp3"
}

resource "aws_instance" "nodes" {
  for_each = local.node_types
  
  count             = each.value.config.count
  ami               = local.amis[var.os_type]
  instance_type     = each.value.config.instance_type
  subnet_id         = element(var.subnet_ids, index(data.aws_availability_zones.available.names, each.value.azs[count.index % length(each.value.azs)]))
  security_groups   = [aws_security_group.es_nodes.id]
  availability_zone = each.value.azs[count.index % length(each.value.azs)]
  iam_instance_profile = var.iam_instance_profile
  
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  dynamic "ebs_block_device" {
    for_each = contains(["i3", "c5d", "m5d"], split(".", each.value.config.instance_type)[0]) ? [] : [1]
    content {
      device_name = "/dev/sdh"
      volume_size = var.data_volume_size
      volume_type = "gp3"
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = contains(["i3", "c5d", "m5d"], split(".", each.value.config.instance_type)[0]) ? [1] : []
    content {
      device_name = "/dev/nvme1n1"
      virtual_name = "ephemeral0"
    }
  }

  tags = {
    Name = "${var.cluster_name}-${each.key}-${count.index}"
    Role = each.key
  }
}

resource "aws_volume_attachment" "elastic_install" {
  for_each = { for role, instances in aws_instance.nodes : role => instances[*] }
  count    = each.value[count.index].count
  
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.elastic_install[each.key][count.index].id
  instance_id = each.value[count.index].id
}

resource "aws_volume_attachment" "elastic_logs" {
  for_each = { for role, instances in aws_instance.nodes : role => instances[*] }
  count    = each.value[count.index].count
  
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.elastic_logs[each.key][count.index].id
  instance_id = each.value[count.index].id
}

resource "aws_volume_attachment" "elastic_data" {
  for_each = { for role, instances in aws_instance.nodes : role => instances[*] if !contains(["i3", "c5d", "m5d"], split(".", local.node_types[each.key].config.instance_type)[0]) }
  count    = each.value[count.index].count
  
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.elastic_data[each.key][count.index].id
  instance_id = each.value[count.index].id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "local_file" "elastic_agent_config" {
  count    = var.enable_monitoring ? 1 : 0
  filename = "${path.module}/../../../ansible/${var.cluster_name}-elastic-agent.yml"
  content  = templatefile("${path.module}/templates/elastic-agent.yml.tmpl", {
    cluster_name       = var.cluster_name
    cluster_type       = var.cluster_type
    monitoring_endpoint = var.monitoring_endpoint
    node_roles         = join(",", keys(local.node_types))
  })
}