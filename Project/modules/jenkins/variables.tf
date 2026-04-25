variable "chart_version" {
  description = "Version of the Jenkins Helm chart"
  type        = string
  default     = "5.1.4"
}

variable "namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "admin_username" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}
