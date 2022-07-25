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
resource "kubectl_manifest" "cert_manager_clusterissuer" {
  depends_on         = [helm_release.cert_manager]
  override_namespace = "cert-manager"
  yaml_body          = file("./charts/cert-manager/issuer.yaml")
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
    file("./charts/ingress-nginx/values-cluster-gitops.yaml")
  ]
}

# install argo-cd helm chart
resource "helm_release" "argo_cd" {
  depends_on      = [helm_release.ingress_nginx]
  repository      = "https://argoproj.github.io/argo-helm"
  chart           = "argo-cd"
  name            = "argocd"
  namespace       = "argocd"
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
      argocd login argocd.gitops.local:4431 --grpc-web --insecure --username admin --password password && \
      argocd cluster add --name dev k3d-dev --yes && \
      argocd cluster add --name stage k3d-stage --yes && \
      argocd cluster add --name prod k3d-prod --yes
    EOF
  }
}

# apply argocd git repo manifests
data "kubectl_filename_list" "argocd_repos" {
  pattern = "./charts/argo-cd/repos/*.yaml"
}

resource "kubectl_manifest" "argocd_repos" {
  depends_on         = [null_resource.connect_argocd]
  override_namespace = "argocd"
  count              = length(data.kubectl_filename_list.argocd_repos.matches)
  yaml_body          = file(element(data.kubectl_filename_list.argocd_repos.matches, count.index))
}

resource "kubectl_manifest" "argocd_apps" {
  depends_on         = [kubectl_manifest.argocd_repos]
  override_namespace = "argocd"
  yaml_body          = file("./charts/argo-cd/multi-cluster-apps/applicationset.yaml")
}
