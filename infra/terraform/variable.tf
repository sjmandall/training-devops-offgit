variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "training-site"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 80
}

variable "minikube_ip" {
  description = "Minikube IP address for hosts mapping"
  type        = string
  default     = "192.168.49.2"
}

variable "host_entry" {
  description = "Hostname for the app"
  type        = string
  default     = "mysite.sj"
}

variable "db_host" {
  description = "Database host"
  type        = string
  default     = "localhost"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "trainingdb"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "trainingapp"
}

variable "output_dir" {
  description = "Directory where config files will be created"
  type        = string
  default     = "/tmp/terraform-output"
}


