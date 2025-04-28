locals {
  required_providers = {
    kubectl = {
      source = "gavinbunney/kubectl"
    }

    helm = {
      source = "hashicorp/helm"
    }

    http = {
      source = "hashicorp/http"
    }
  }
}
