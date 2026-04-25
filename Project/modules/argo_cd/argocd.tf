resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  timeout          = 600

  values = [file("${path.module}/values.yaml")]
}

resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = var.namespace
  timeout   = 300

  set {
    name  = "applications[0].repoURL"
    value = var.git_repo_url
  }

  set {
    name  = "applications[0].path"
    value = var.git_repo_path
  }

  set {
    name  = "applications[0].targetRevision"
    value = var.target_revision
  }

  set {
    name  = "repositories[0].url"
    value = var.git_repo_url
  }

  depends_on = [helm_release.argocd]
}
