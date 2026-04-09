output "app_name" {
  description = "Application name"
  value       = var.app_name
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "hosts_mapping_file" {
  description = "Path to generated hosts mapping file"
  value       = local_file.hosts_mapping.filename
}

output "app_config_file" {
  description = "Path to generated app config file"
  value       = local_file.app_config.filename
}

output "deployment_info_file" {
  description = "Path to generated deployment info file"
  value       = local_file.deployment_info.filename
}

output "app_url" {
  description = "Application URL"
  value       = "http://${var.host_entry}"
}

