# Cluster configuration definitions for Elasticsearch clusters.
# Modify the definitions below to add, remove or update clusters.

business_clusters = {
  fincrimes = {
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

  vectorsearch = {
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

monitoring_config = {
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
