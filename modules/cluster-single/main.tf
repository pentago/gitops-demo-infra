# partition cluster with namespaces
resource "kubernetes_namespace" "create_namespaces" {
  for_each = {
    for namespace in var.kubernetes_namespaces : namespace => namespace
  }
  metadata {
    name = each.value
  }
}

# apply cert-manager ca secret manifest
resource "kubectl_manifest" "cert_manager_ca_secret" {
  depends_on         = [kubernetes_namespace.create_namespaces]
  override_namespace = "cert-manager"
  yaml_body          = file("./certs/ca-secret.yaml")
}

# install cert-manager helm chart
resource "helm_release" "cert_manager" {
  depends_on       = [kubectl_manifest.cert_manager_ca_secret]
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  cleanup_on_fail  = true
  values = [
    file("./charts/cert-manager/values.yaml")
  ]
}

# apply cert-manager clusterissuer manifest
data "kubectl_file_documents" "cert_manager_clusterissuer" {
  content = file("./charts/cert-manager/issuer.yaml")
}

resource "kubectl_manifest" "cert_manager_clusterissuer" {
  depends_on         = [helm_release.cert_manager]
  override_namespace = "cert-manager"
  count              = length(data.kubectl_file_documents.cert_manager_clusterissuer.documents)
  yaml_body          = element(data.kubectl_file_documents.cert_manager_clusterissuer.documents, count.index)
}

# install ingress-nginx helm chart
resource "helm_release" "ingress_nginx" {
  depends_on       = [kubectl_manifest.cert_manager_clusterissuer]
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  cleanup_on_fail  = true
  values = [
    file("./charts/ingress-nginx/values-cluster-single.yaml")
  ]
}

# install argo-cd helm chart
resource "helm_release" "argo_cd" {
  depends_on      = [helm_release.ingress_nginx]
  repository      = "https://argoproj.github.io/argo-helm"
  chart           = "argo-cd"
  name            = "argocd"
  namespace       = "argocd"
  timeout         = 120
  create_namespace = true
  cleanup_on_fail = true
  values = [
    file("./charts/argo-cd/values.yaml")
  ]
}

  # login to ArgoCD instance and add cluster to it
resource "null_resource" "connect_argocd" {
  depends_on         = [helm_release.argo_cd]

  provisioner "local-exec" {
    command = <<-EOF
      argocd login argocd.gitops.local --grpc-web --insecure --username admin --password password
      argocd cluster add --name single-cluster k3d-single --yes
    EOF
  }
}

# apply argocd git repo key manifests
data "kubectl_filename_list" "argocd_repos" {
  pattern = "./charts/argo-cd/repos/*.yaml"
}

resource "kubectl_manifest" "argocd_repos" {
  depends_on         = [null_resource.connect_argocd]
  override_namespace = "argocd"
  count              = length(data.kubectl_filename_list.argocd_repos.matches)
  yaml_body          = file(element(data.kubectl_filename_list.argocd_repos.matches, count.index))
}

# apply argocd app manifests
data "kubectl_filename_list" "argocd_apps" {
  pattern = "./charts/argo-cd/single-cluster-apps/*.yaml"
}

resource "kubectl_manifest" "argocd_apps" {
  depends_on         = [kubectl_manifest.argocd_repos]
  override_namespace = "argocd"
  count              = length(data.kubectl_filename_list.argocd_apps.matches)
  yaml_body          = file(element(data.kubectl_filename_list.argocd_apps.matches, count.index))
}

  # sync ArgoCD apps
resource "null_resource" "sync_argocd" {
  depends_on         = [kubectl_manifest.argocd_apps]

  provisioner "local-exec" {
    command = <<-EOF
      argocd app sync --async --force -l app=gitops-demo
    EOF
  }
}