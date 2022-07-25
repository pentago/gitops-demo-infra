# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3d-single"
}

# https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs
provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "k3d-single"
}

# https://registry.terraform.io/providers/hashicorp/helm/latest/docs
provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "k3d-single"
  }
}
