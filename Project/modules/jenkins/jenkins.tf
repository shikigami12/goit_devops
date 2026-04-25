resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  timeout          = 600

  values = [file("${path.module}/values.yaml")]

  set {
    name  = "controller.admin.username"
    value = var.admin_username
  }

  set_sensitive {
    name  = "controller.admin.password"
    value = var.admin_password
  }
}
