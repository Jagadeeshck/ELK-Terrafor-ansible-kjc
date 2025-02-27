variable "cluster_name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "cluster_type" { type = string }
variable "node_configs" {
  type = object({
    master_nodes = object({
      count         = number
      instance_type = string
      root_size     = number
      elastic_size  = number
      logs_size     = number
      data_size     = number
    })
    data_nodes = object({
      count         = number
      instance_type = string
      root_size     = number
      elastic_size  = number
      logs_size     = number
      data_size     = number
    })
    kibana_nodes = object({
      count         = number
      instance_type = string
      root_size     = number
      elastic_size  = number
      logs_size     = number
      data_size     = number
    })
    ml_nodes = object({
      count         = number
      instance_type = string
      root_size     = number
      elastic_size  = number
      logs_size     = number
      data_size     = number
    })
    logstash_nodes = optional(object({
      count         = number
      instance_type = string
      root_size     = number
      elastic_size  = number
      logs_size     = number
      data_size     = number
    }))
    apm_nodes = optional(object({
      count         = number
      instance_type = string
      root_size     = number
      elastic_size  = number
      logs_size     = number
      data_size     = number
    }))
    fleet_nodes = optional(object({
      count         = number
      instance_type = string
      root_size     = number
      elastic_size  = number
      logs_size     = number
      data_size     = number
    }))
  })
}
variable "enable_monitoring" { type = bool }
variable "monitoring_endpoint" {
  type    = string
  default = "" # Make it optional with an empty string default
}
variable "aws_region" { type = string }
variable "az_count" { type = number }
variable "az_mappings" { type = any }
variable "iam_instance_profile" { type = string }
variable "snapshot_bucket" { type = string }
variable "os_type" { type = string }
variable "elasticsearch_version" { type = string }