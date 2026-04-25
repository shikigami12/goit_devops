variable "chart_version" {
  description = "Version of the Argo CD Helm chart"
  type        = string
  default     = "7.3.11"
}

variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "git_repo_url" {
  description = "Git repository URL that Argo CD watches for the django-app chart"
  type        = string
}

variable "git_repo_path" {
  description = "Path within the Git repo containing the django-app Helm chart"
  type        = string
  default     = "lesson-8/charts/django-app"
}

variable "target_revision" {
  description = "Git branch/tag Argo CD tracks"
  type        = string
  default     = "main"
}
