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
  # Flatten node instances into a map for for_each
  instances = flatten([
    for role, details in local.node_types : [
      for i in range(details.config.count) : {
        key           = "${role}-${i}"
        role          = role
        instance_type = details.config.instance_type
        az            = details.azs[i % length(details.azs)]
        subnet_id     = element(var.subnet_ids, index(data.aws_availability_zones.available.names, details.azs[i % length(details.azs)]))
      }
    ]
  ])
  instance_map = { for inst in local.instances : inst.key => inst }
}

resource "aws_instance" "nodes" {
  for_each = local.instance_map

  ami               = local.amis[var.os_type]
  instance_type     = each.value.instance_type
  subnet_id         = each.value.subnet_id
  security_groups   = [aws_security_group.es_nodes.id]
  availability_zone = each.value.az
  iam_instance_profile = var.iam_instance_profile

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  dynamic "ebs_block_device" {
    for_each = contains(["i3", "c5d", "m5d"], split(".", each.value.instance_type)[0]) ? [] : [1]
    content {
      device_name = "/dev/sdh"
      volume_size = var.data_volume_size
      volume_type = "gp3"
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = contains(["i3", "c5d", "m5d"], split(".", each.value.instance_type)[0]) ? [1] : []
    content {
      device_name = "/dev/nvme1n1"
      virtual_name = "ephemeral0"
    }
  }

  tags = {
    Name = "${var.cluster_name}-${each.value.role}-${split("-", each.key)[1]}"
    Role = each.value.role
  }
}

resource "aws_ebs_volume" "elastic_install" {
  for_each = local.instance_map

  availability_zone = each.value.az
  size              = 50
  type              = "gp3"
  tags = {
    Name = "${var.cluster_name}-${each.value.role}-install-${split("-", each.key)[1]}"
  }
}

resource "aws_ebs_volume" "elastic_logs" {
  for_each = local.instance_map

  availability_zone = each.value.az
  size              = 50
  type              = "gp3"
  tags = {
    Name = "${var.cluster_name}-${each.value.role}-logs-${split("-", each.key)[1]}"
  }
}

resource "aws_ebs_volume" "elastic_data" {
  for_each = { for key, inst in local.instance_map : key => inst if !contains(["i3", "c5d", "m5d"], split(".", inst.instance_type)[0]) }

  availability_zone = each.value.az
  size              = var.data_volume_size
  type              = "gp3"
  tags = {
    Name = "${var.cluster_name}-${each.value.role}-data-${split("-", each.key)[1]}"
  }
}

resource "aws_volume_attachment" "elastic_install" {
  for_each = local.instance_map

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.elastic_install[each.key].id
  instance_id = aws_instance.nodes[each.key].id
}

resource "aws_volume_attachment" "elastic_logs" {
  for_each = local.instance_map

  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.elastic_logs[each.key].id
  instance_id = aws_instance.nodes[each.key].id
}

resource "aws_volume_attachment" "elastic_data" {
  for_each = { for key, inst in local.instance_map : key => inst if !contains(["i3", "c5d", "m5d"], split(".", inst.instance_type)[0]) }

  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.elastic_data[each.key].id
  instance_id = aws_instance.nodes[each.key].id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "local_file" "elastic_agent_config" {
  count    = var.enable_monitoring ? 1 : 0
  filename = "${path.module}/../../../ansible/${var.cluster_name}-elastic-agent.yml"
  content  = templatefile("${path.module}/templates/elastic-agent.yml.tmpl", {
    cluster_name        = var.cluster_name
    cluster_type        = var.cluster_type
    monitoring_endpoint = var.monitoring_endpoint
    node_roles          = join(",", keys(local.node_types))
  })
}