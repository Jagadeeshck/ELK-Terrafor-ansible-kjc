output "instances" {
  value = {
    for role, details in local.node_types : role => [
      for i in range(details.config.count) : {
        id         = aws_instance.nodes["${role}-${i}"].id
        private_ip = aws_instance.nodes["${role}-${i}"].private_ip
      }
    ]
  }
}

output "master_instances" {
  value = [for i in range(local.node_types["master"].config.count) : aws_instance.nodes["master-${i}"]]
}

output "data_instances" {
  value = [for i in range(local.node_types["data"].config.count) : aws_instance.nodes["data-${i}"]]
}

output "kibana_instances" {
  value = [for i in range(local.node_types["kibana"].config.count) : aws_instance.nodes["kibana-${i}"]]
}

output "fleet_endpoint" {
  value = lookup(local.node_types, "fleet", null) != null ? (
    local.node_types["fleet"].config.count > 1 ? 
      "fleet-monitoring-cluster.kjc.infotech.net" : 
      aws_instance.nodes["fleet-0"].private_ip
  ) : ""
}