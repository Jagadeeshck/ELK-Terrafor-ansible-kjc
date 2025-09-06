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
  } : merge(
    {
      "master"   = { config = var.node_configs.master_nodes, azs = var.az_mappings.master_nodes }
      "data"     = { config = var.node_configs.data_nodes, azs = var.az_mappings.data_nodes }
      "kibana"   = { config = var.node_configs.kibana_nodes, azs = var.az_mappings.kibana_nodes }
      "ml"       = { config = var.node_configs.ml_nodes, azs = var.az_mappings.ml_nodes }
    },
    var.node_configs.logstash_nodes != null ? { "logstash" = { config = var.node_configs.logstash_nodes, azs = var.az_mappings.logstash_nodes } } : {},
    var.node_configs.apm_nodes != null ? { "apm" = { config = var.node_configs.apm_nodes, azs = var.az_mappings.apm_nodes } } : {},
    var.node_configs.fleet_nodes != null ? { "fleet" = { config = var.node_configs.fleet_nodes, azs = var.az_mappings.fleet_nodes } } : {}
  )
  amis = {
    "centos"        = "ami-centos-7-latest" # Replace with actual AMI ID
    "rhel"          = "ami-rhel-8-latest"   # Replace with actual AMI ID
    "amazon-linux"  = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  }
  # Ensure var.os_type is one of the above keys: "centos", "rhel", or "amazon-linux"
  instances = flatten([
    for role, details in local.node_types : [
      for i in range(details.config.count) : {
        key           = "${role}-${i}"
        role          = role
        instance_type = details.config.instance_type
        subnet_id     = var.subnet_ids[i % length(var.subnet_ids)]
        subnet_id     = element(var.subnet_ids, index(data.aws_availability_zones.available.names, details.azs[i % length(details.azs)]))
        root_size     = details.config.root_size
        elastic_size  = details.config.elastic_size
        logs_size     = details.config.logs_size
        data_size     = details.config.data_size
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
    volume_size = each.value.root_size
    volume_type = "gp3"
  }

  dynamic "ebs_block_device" {
    for_each = contains(["i3", "c5d", "m5d"], split(".", each.value.instance_type)[0]) ? [] : [1]
    content {
      device_name = "/dev/sdh"
      volume_size = each.value.data_size
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
  size              = each.value.elastic_size
  type              = "gp3"
  tags = {
    Name = "${var.cluster_name}-${each.value.role}-install-${split("-", each.key)[1]}"
  }
}

resource "aws_ebs_volume" "elastic_logs" {
  for_each = local.instance_map

  availability_zone = each.value.az
  size              = each.value.logs_size
  type              = "gp3"
  tags = {
    Name = "${var.cluster_name}-${each.value.role}-logs-${split("-", each.key)[1]}"
  }
}

resource "aws_ebs_volume" "elastic_data" {
  for_each = { for key, inst in local.instance_map : key => inst if !contains(["i3", "c5d", "m5d"], split(".", inst.instance_type)[0]) }

  availability_zone = each.value.az
  size              = each.value.data_size
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