# Elasticsearch Infrastructure with Terraform and Ansible

This repository contains Terraform and Ansible code to deploy Elasticsearch clusters on AWS with separate node roles, cross-account access, and custom storage configurations.

## Features
- Multi-cluster deployment (Business and Monitoring).
- Separate node roles: Master, Data, Kibana, ML, Fleet, APM, Logstash.
- Cross-account access to Monitoring cluster (configurable).
- Custom storage: EBS for root and logs, instance store or EBS for data.
- Automated Ansible provisioning for installation and configuration.
- Load balancers and Route 53 DNS for multi-instance roles.

## Prerequisites
- Terraform >= 1.0
- Ansible >= 2.9
- AWS CLI configured with credentials
- SSH key pair for EC2 instances

## Usage
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd elasticsearch-infra


# S3 Preparation:
Upload binaries to kjc-elasticsearch-binaries-<region>:

   ```bash
aws s3 cp elasticsearch-7.10.0-linux-x86_64.tar.gz s3://kjc-elasticsearch-binaries-us-east-1/
aws s3 cp kibana-7.10.0-linux-x86_64.tar.gz s3://kjc-elasticsearch-binaries-us-east-1/

# Repeat for other components and versions:

## For "latest", create a symbolic link or copy the latest version:

# terraform.tfvars
elasticsearch_version = "7.10.0"  # Or "latest"

Notes
JVM Customization: Adjust heap sizes (-Xms, -Xmx) in jvm.options.j2 based on your instance types (e.g., t3.medium might need smaller heaps).
Latest Version: Ensure the S3 bucket has a *-latest-linux-x86_64.tar.gz file for each component if using the default latest.
Fleet Configuration: Fleet nodes run Elasticsearch with the fleet role, but agent configuration is deferred until needed.
