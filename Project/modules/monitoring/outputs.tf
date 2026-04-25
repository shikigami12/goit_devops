output "grafana_portforward_command" {
  description = "Command to access Grafana locally on port 3000"
  value       = "kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n ${var.namespace}"
}

output "prometheus_portforward_command" {
  description = "Command to access Prometheus locally on port 9090"
  value       = "kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n ${var.namespace}"
}
