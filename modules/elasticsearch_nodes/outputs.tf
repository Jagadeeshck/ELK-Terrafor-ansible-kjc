output "instances" {
  value = {
    for role, instances in aws_instance.nodes : role => [
      for idx, inst in instances : {
        id         = inst.id
        private_ip = inst.private_ip_address
      }
    ]
  }
}

output "master_instances" {
  value = [for inst in aws_instance.nodes["master"] : inst]
}

output "data_instances" {
  value = [for inst in aws_instance.nodes["data"] : inst]
}

output "kibana_instances" {
  value = [for inst in aws_instance.nodes["kibana"] : inst]
}

output "fleet_endpoint" {
  value = length(aws_instance.nodes["fleet"]) > 1 ? 
    "fleet-monitoring-cluster.kjc.infotech.net" : 
    aws_instance.nodes["fleet"][0].private_ip_address
}