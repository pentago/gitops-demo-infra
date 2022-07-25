# Kubernetes Variables

variable "kubernetes_namespaces" {
  type    = list(string)
  default = ["cert-manager"]
}
