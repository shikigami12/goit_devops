output "namespace" {
  description = "Kubernetes namespace where Jenkins is installed"
  value       = helm_release.jenkins.namespace
}

output "jenkins_url_command" {
  description = "Command to retrieve the Jenkins LoadBalancer hostname"
  value       = "kubectl get svc jenkins -n ${helm_release.jenkins.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}
