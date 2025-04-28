locals {
  required_providers = {
    kubectl = {
      source = "gavinbunney/kubectl"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }

    http = {
      source = "hashicorp/http"
    }
  }
}
