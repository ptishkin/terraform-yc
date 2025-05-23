terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }

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

  required_version = ">= 0.13"
}
