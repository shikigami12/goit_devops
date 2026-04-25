output "argocd_server_command" {
  description = "Command to get the Argo CD server hostname"
  value       = "kubectl get svc argocd-server -n ${var.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "argocd_initial_password_command" {
  description = "Command to retrieve the initial Argo CD admin password"
  value       = "kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
