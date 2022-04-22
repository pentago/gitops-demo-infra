terraform {
  required_providers {
    local      = {
      source   = "hashicorp/local"
      version  = "2.2.2"
    }

    null      = {
      source   = "hashicorp/null"
      version  = "3.1.1"
    }

    kubernetes = {
      source   = "hashicorp/kubernetes"
      version  = "2.10.0"
    }

    kubectl    = {
      source   = "gavinbunney/kubectl"
      version  = "1.14.0"
    }

    helm       = {
      source   = "hashicorp/helm"
      version  = "2.5.1"
    }
  }
}
