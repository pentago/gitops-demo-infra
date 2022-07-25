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
    file("./charts/ingress-nginx/values-cluster-dev.yaml")
  ]
}
