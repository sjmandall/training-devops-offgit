# Day 20 Terraform - Local IaC + State Management

## What this does
Uses Terraform with a local backend to generate config artifacts
and manage them via state. Creates files for host mappings and
app configuration. Destroy cleans up all artifacts.

## Variables

| Variable    | Type   | Default         | Description                        |
|-------------|--------|-----------------|------------------------------------|
| app_name    | string | training-site   | Name of the application            |
| environment | string | dev             | Deployment environment             |
| app_port    | number | 80              | Port the application listens on    |
| minikube_ip | string | 192.168.49.2    | Minikube IP for hosts mapping      |
| host_entry  | string | mysite.sj       | Hostname for the app               |
| db_host     | string | localhost       | Database host                      |
| db_name     | string | trainingdb      | Database name                      |
| db_user     | string | trainingapp     | Database username                  |
| output_dir  | string | /tmp/terraform-output | Output directory for files   |

## Outputs

| Output               | Description                          |
|----------------------|--------------------------------------|
| app_name             | Application name                     |
| environment          | Deployment environment               |
| hosts_mapping_file   | Path to generated hosts mapping file |
| app_config_file      | Path to generated app config file    |
| deployment_info_file | Path to generated deployment info    |
| app_url              | Application URL                      |

## Commands

  terraform init     - Initialize providers and backend
  terraform plan     - Preview what will be created
  terraform apply    - Create all resources (files)
  terraform destroy  - Delete all created resources

## Files created by Terraform

  /tmp/terraform-output/hosts-mapping.txt   - hosts entry for mysite.sj
  /tmp/terraform-output/app.env             - application config
  /tmp/terraform-output/deployment-info.txt - deployment details

## State management

  terraform.tfstate     - local state file tracking all resources
  terraform.tfstate.backup - backup of previous state

