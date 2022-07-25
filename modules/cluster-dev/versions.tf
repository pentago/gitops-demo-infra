terraform {
  required_providers {
    local      = {
      source   = "hashicorp/local"
      version  = "2.2.3"
    }

    kubernetes = {
      source   = "hashicorp/kubernetes"
      version  = "2.12.1"
    }

    kubectl    = {
      source   = "gavinbunney/kubectl"
      version  = "1.14.0"
    }

    helm       = {
      source   = "hashicorp/helm"
      version  = "2.6.0"
    }
  }
}