variable "aws_region" {
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "az_count" {
  description = "Number of Availability Zones to use"
  default     = 2
}

variable "enable_cross_account" {
  description = "Enable cross-account access to monitoring cluster"
  type        = bool
  default     = false
}

variable "cross_account_id" {
  description = "AWS Account ID for cross-account access"
  type        = string
  default     = ""
}

variable "business_clusters" {
  type = map(object({
    enable_monitoring = bool
    node_configs = object({
      master_nodes = object({ count = number, instance_type = string })
      data_nodes   = object({ count = number, instance_type = string })
      kibana_nodes = object({ count = number, instance_type = string })
      ml_nodes     = object({ count = number, instance_type = string })
    })
    az_mappings = object({
      master_nodes = list(string)
      data_nodes   = list(string)
      kibana_nodes = list(string)
      ml_nodes     = list(string)
    })
    os_type          = string
    root_volume_size = number
    data_volume_size = number
  }))
  default = {
    "business-1" = {
      enable_monitoring = true
      node_configs = {
        master_nodes = { count = 3, instance_type = "t3.medium" }
        data_nodes   = { count = 3, instance_type = "i3.large" }
        kibana_nodes = { count = 1, instance_type = "t3.medium" }
        ml_nodes     = { count = 2, instance_type = "t3.large" }
      }
      az_mappings = {
        master_nodes = ["us-east-1a", "us-east-1b", "us-east-1c"]
        data_nodes   = ["us-east-1a", "us-east-1b", "us-east-1c"]
        kibana_nodes = ["us-east-1a"]
        ml_nodes     = ["us-east-1b", "us-east-1c"]
      }
      os_type          = "amazon-linux"
      root_volume_size = 20
      data_volume_size = 100
    }
  }
}

variable "monitoring_config" {
  type = object({
    node_configs = object({
      master_nodes   = object({ count = number, instance_type = string })
      data_nodes     = object({ count = number, instance_type = string })
      kibana_nodes   = object({ count = number, instance_type = string })
      logstash_nodes = object({ count = number, instance_type = string })
      apm_nodes      = object({ count = number, instance_type = string })
      fleet_nodes    = object({ count = number, instance_type = string })
      ml_nodes       = object({ count = number, instance_type = string })
    })
    az_mappings = object({
      master_nodes   = list(string)
      data_nodes     = list(string)
      kibana_nodes   = list(string)
      logstash_nodes = list(string)
      apm_nodes      = list(string)
      fleet_nodes    = list(string)
      ml_nodes       = list(string)
    })
    os_type          = string
    root_volume_size = number
    data_volume_size = number
  })
  default = {
    node_configs = {
      master_nodes   = { count = 3, instance_type = "t3.medium" }
      data_nodes     = { count = 4, instance_type = "i3.large" }
      kibana_nodes   = { count = 2, instance_type = "t3.medium" }
      logstash_nodes = { count = 2, instance_type = "t3.medium" }
      apm_nodes      = { count = 1, instance_type = "t3.medium" }
      fleet_nodes    = { count = 1, instance_type = "t3.medium" }
      ml_nodes       = { count = 2, instance_type = "t3.large" }
    }
    az_mappings = {
      master_nodes   = ["us-east-1a", "us-east-1b", "us-east-1c"]
      data_nodes     = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
      kibana_nodes   = ["us-east-1a", "us-east-1b"]
      logstash_nodes = ["us-east-1c", "us-east-1d"]
      apm_nodes      = ["us-east-1a"]
      fleet_nodes    = ["us-east-1b"]
      ml_nodes       = ["us-east-1c", "us-east-1d"]
    }
    os_type          = "amazon-linux"
    root_volume_size = 20
    data_volume_size = 100
  }
}