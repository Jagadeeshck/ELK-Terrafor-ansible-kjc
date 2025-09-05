***

# ELK-Terrafor-Ansible-KJC

***

## 🚀 Overview

This repository provides a **modular solution for deploying and managing Elasticsearch clusters** on AWS using Terraform for infrastructure and Ansible for configuration management. Supports multi-cluster setups, advanced storage, high availability, and integrated cluster monitoring.

 <!-- cluster diagram  -->

***

## ✨ Features

- **Multi-cluster deployments**: Deploy business and monitoring clusters.
- **Node specialization**: Master, Data, Kibana, ML, Logstash, Fleet, APM roles.
- **Cross-account access:** Support for shared monitoring clusters.
- **Flexible storage:** EBS for root/logs, instance/EBS for data.
- **Automated provisioning:** Ansible automation for post-deploy install/configuration.
- **HA ready:** ELBs and Route53 for fault-tolerant roles and services.

***

## 📦 Prerequisites

- Terraform **1.0+**
- Ansible **2.9+**
- AWS CLI (setup with credentials)
- SSH key pair for EC2 access

***

## 🛠️ Usage

### 1. Clone this repo

```bash
git clone https://github.com/Jagadeeshck/ELK-Terrafor-ansible-kjc.git
cd ELK-Terrafor-ansible-kjc
```

### 2. S3 Preparation

Upload the required binaries:

```bash
aws s3 cp elasticsearch-7.10.0-linux-x86_64.tar.gz s3://YOUR-BUCKET/
aws s3 cp kibana-7.10.0-linux-x86_64.tar.gz s3://YOUR-BUCKET/
# ...repeat for all components
```

### 3. Cluster Configuration

Edit `clusters.auto.tfvars` to define your clusters, node counts, instance types, disk sizes, and AZs.

### 4. Deploy Infrastructure

```bash
terraform init
terraform apply
```

### 5. Run Ansible provisioning

Configure inventory if needed, then:

```bash
ansible-playbook -i ansible/inventory/hosts ansible/deploy.yml
```

> See the [README.md](ansible/README.md) (or create it!) for Ansible provisioning and role details.

***

## 📝 Example `clusters.auto.tfvars`

```hcl
business_cluster = {
  enable_monitoring = true
  node_configs = {
    master = { count = 3, instance_type = "t3.medium", ... }
    data   = { ... }
    # ...
  }
  az_mappings = { ... }
}

# Additional clusters...
```

***

## 🖼️ Architecture

<!-- Add or update diagram paths if you create more architecture diagrams/grafana screenshots -->


***

## 📄 License

This repo is MIT licensed. See [LICENSE](LICENSE) for details.

***

## 🙋 FAQ & Troubleshooting

- **Q:** How do I add a new cluster?
- **A:** Copy and update the corresponding entry in `clusters.auto.tfvars` and re-run `terraform apply`.

- **Q:** How do I customize JVM/Elasticsearch settings?
- **A:** Edit the relevant files in [templates](templates/) and update resources as needed.

- **Q:** Where can I view deployment logs?
- **A:** Check your Terraform and Ansible CLI output for step-by-step logs.

***

## 🤝 Contributing

PRs are welcome! Please open issues or reply on [discussions](../../discussions) for suggestions.

***

## 👤 Maintainer

- [Jagadeeshck](https://github.com/Jagadeeshck)

***

**You can copy and paste this template into your README.md. Want me to suggest content for any specific section or help with badges, diagrams, or FAQ items?**

[1](https://github.com/Jagadeeshck/ansible-freeipa)
