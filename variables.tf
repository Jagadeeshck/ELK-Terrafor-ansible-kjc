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

variable "elasticsearch_version" {
  description = "Elasticsearch version to use (e.g., '7.10.0', '8.5.0'); defaults to latest from S3 if not specified"
  type        = string
  default     = "latest"
}

variable "business_clusters" {
  type = map(object({
    enable_monitoring = bool
    node_configs = object({
      master_nodes = object({
        count         = number
        instance_type = string
        root_size     = number # GB
        elastic_size  = number # GB
        logs_size     = number # GB
        data_size     = number # GB
      })
      data_nodes = object({
        count         = number
        instance_type = string
        root_size     = number # GB
        elastic_size  = number # GB
        logs_size     = number # GB
        data_size     = number # GB
      })
      kibana_nodes = object({
        count         = number
        instance_type = string
        root_size     = number # GB
        elastic_size  = number # GB
        logs_size     = number # GB
        data_size     = number # GB
      })
      ml_nodes = object({
        count         = number
        instance_type = string
        root_size     = number # GB
        elastic_size  = number # GB
        logs_size     = number # GB
        data_size     = number # GB
      })
    })
    az_mappings = object({
      master_nodes = list(string)
      data_nodes   = list(string)
      kibana_nodes = list(string)
      ml_nodes     = list(string)
    })
    os_type = string
  }))
  default = {
    "fincrimes" = {
      enable_monitoring = true
      node_configs = {
        master_nodes = {
          count         = 3
          instance_type = "t3.medium"
          root_size     = 100
          elastic_size  = 50
          logs_size     = 50
          data_size     = 200
        }
        data_nodes = {
          count         = 3
          instance_type = "i3.large"
          root_size     = 100
          elastic_size  = 50
          logs_size     = 50
          data_size     = 1000
        }
        kibana_nodes = {
          count         = 1
          instance_type = "t3.medium"
          root_size     = 100
          elastic_size  = 50
          logs_size     = 50
          data_size     = 200
        }
        ml_nodes = {
          count         = 2
          instance_type = "t3.large"
          root_size     = 100
          elastic_size  = 50
          logs_size     = 50
          data_size     = 200
        }
      }
      az_mappings = {
        master_nodes = ["us-east-1a", "us-east-1b", "us-east-1c"]
        data_nodes   = ["us-east-1a", "us-east-1b", "us-east-1c"]
        kibana_nodes = ["us-east-1a"]
        ml_nodes     = ["us-east-1b", "us-east-1c"]
      }
      os_type = "amazon-linux"
    }
    "vectorsearch" = {
      enable_monitoring = true
      node_configs = {
        master_nodes = {
          count         = 3
          instance_type = "t3.medium"
          root_size     = 100
          elastic_size  = 50
          logs_size     = 50
          data_size     = 200
        }
        data_nodes = {
          count         = 4
          instance_type = "i3.large"
          root_size     = 100
          elastic_size  = 50
          logs_size     = 50
          data_size     = 1000
        }
        kibana_nodes = {
          count         = 2
          instance_type = "t3.medium"
          root_size     = 100
          elastic_size  = 50
          logs_size     = 50
          data_size     = 200
        }
        ml_nodes = {
          count         = 2
          instance_type = "t3.large"
          root_size     = 100
          elastic_size  = 50
          logs_size     = 50
          data_size     = 200
        }
      }
      az_mappings = {
        master_nodes = ["us-east-1a", "us-east-1b", "us-east-1c"]
        data_nodes   = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
        kibana_nodes = ["us-east-1a", "us-east-1b"]
        ml_nodes     = ["us-east-1c", "us-east-1d"]
      }
      os_type = "amazon-linux"
    }
  }
}

variable "monitoring_config" {
  type = object({
    node_configs = object({
      master_nodes = object({
        count         = number
        instance_type = string
        root_size     = number # GB
        elastic_size  = number # GB
        logs_size     = number # GB
        data_size     = number # GB
      })
      data_nodes = object({
        count         = number
        instance_type = string
        root_size     = number # GB
        elastic_size  = number # GB
        logs_size     = number # GB
        data_size     = number # GB
      })
      kibana_nodes = object({
        count         = number
        instance_type = string
        root_size     = number # GB
        elastic_size  = number # GB
        logs_size     = number # GB
        data_size     = number # GB
      })
      logstash_nodes = object({
        count         = number
        instance_type = string
        root_size     = number # GB
        elastic_size  = number # GB
        logs_size     = number # GB
        data_size     = number # GB
      })
      apm_nodes = object({
        count         = number
        instance_type = string
        root_size     = number # GB
        elastic_size  = number # GB
        logs_size     = number # GB
        data_size     = number # GB
      })
      fleet_nodes = object({
        count         = number
        instance_type = string
        root_size     = number # GB
        elastic_size  = number # GB
        logs_size     = number # GB
        data_size     = number # GB
      })
      ml_nodes = object({
        count         = number
        instance_type = string
        root_size     = number # GB
        elastic_size  = number # GB
        logs_size     = number # GB
        data_size     = number # GB
      })
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
    os_type = string
  })
  default = {
    node_configs = {
      master_nodes = {
        count         = 3
        instance_type = "t3.medium"
        root_size     = 100
        elastic_size  = 50
        logs_size     = 50
        data_size     = 200
      }
      data_nodes = {
        count         = 4
        instance_type = "i3.large"
        root_size     = 100
        elastic_size  = 50
        logs_size     = 50
        data_size     = 1000
      }
      kibana_nodes = {
        count         = 2
        instance_type = "t3.medium"
        root_size     = 100
        elastic_size  = 50
        logs_size     = 50
        data_size     = 200
      }
      logstash_nodes = {
        count         = 2
        instance_type = "t3.medium"
        root_size     = 100
        elastic_size  = 50
        logs_size     = 50
        data_size     = 200
      }
      apm_nodes = {
        count         = 1
        instance_type = "t3.medium"
        root_size     = 100
        elastic_size  = 50
        logs_size     = 50
        data_size     = 200
      }
      fleet_nodes = {
        count         = 1
        instance_type = "t3.medium"
        root_size     = 100
        elastic_size  = 50
        logs_size     = 50
        data_size     = 200
      }
      ml_nodes = {
        count         = 2
        instance_type = "t3.large"
        root_size     = 100
        elastic_size  = 50
        logs_size     = 50
        data_size     = 200
      }
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
    os_type = "amazon-linux"
  }
}
variable "certificate_arn" {
  description = "ARN of the ACM certificate for load balancer HTTPS listeners"
  type        = string
  default     = "" # Replace with your actual ARN or override in terraform.tfvars
}

variable "domain_name" {
  description = "Domain name for Route 53 hosted zone (e.g., kjc.infotech.net)"
  type        = string
  default     = "kjc.infotech.net"
}