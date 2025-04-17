#https://github.com/terraform-yc-modules/terraform-yc-kubernetes/blob/master/variables.tf
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-b"
}

module "yc-vpc" {
  source              = "github.com/terraform-yc-modules/terraform-yc-vpc.git"
  network_name        = "test-module-network"
  network_description = "Test network created with module"
  private_subnets = [
    {
      name           = "subnet-1"
      zone           = "ru-central1-a"
      v4_cidr_blocks = ["10.10.0.0/24"]
    }
  ]
}

module "kube" {
  source     = "github.com/terraform-yc-modules/terraform-yc-kubernetes.git"
  network_id = module.yc-vpc.vpc_id

  master_locations = [
    for s in module.yc-vpc.private_subnets :
    {
      zone      = s.zone,
      subnet_id = s.subnet_id
    }
  ]

  public_access = true
  master_maintenance_windows = [
    {
      day        = "monday"
      start_time = "23:00"
      duration   = "3h"
    }
  ]

  #https://yandex.cloud/en/docs/compute/concepts/performance-levels

  node_groups_defaults = {
    template_name = "{instance_group.id}-{instance.short_id}"
    platform_id   = "standard-v3"
    node_cores    = 2
    node_memory   = 2
    node_gpus     = 0
    core_fraction = 50
    #https://yandex.cloud/en/docs/compute/concepts/disk#disks_types
    disk_type   = "network-hdd"
    disk_size   = 64
    preemptible = false
    nat         = false
    ipv4        = true
    ipv6        = false
  }

  node_groups = {
    "yc-k8s-ng-01" = {
      description = "Kubernetes nodes group 01"
      fixed_scale = {
        size = 1
      }
      node_labels = {
        role        = "worker-01"
        environment = "testing"
      }
    },

    "yc-k8s-ng-02" = {
      description = "Kubernetes nodes group 02"
      auto_scale = {
        min     = 0
        max     = 1
        initial = 0
      }
      node_labels = {
        role        = "worker-02"
        environment = "dev"
      }

      max_expansion   = 1
      max_unavailable = 1
    }
  }
}

module "addons" {
  source = "github.com/terraform-yc-modules/terraform-yc-kubernetes-marketplace"

  cluster_id = module.kube.cluster_id

  install_ingress_nginx = true

  # Full usage example:
  # https://github.com/terraform-yc-modules/terraform-yc-kubernetes-marketplace/tree/main/examples/full
}

#https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/client_config
data "yandex_client_config" "this" {}

provider "kubernetes" {
  host                   = module.kube.external_v4_endpoint
  cluster_ca_certificate = module.kube.cluster_ca_certificate
  token                  = data.yandex_client_config.this.iam_token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = module.kube.external_v4_endpoint
    cluster_ca_certificate = module.kube.cluster_ca_certificate
    token                  = data.yandex_client_config.this.iam_token
  }
  debug = true
}

provider "kubectl" {
  host                   = module.kube.external_v4_endpoint
  cluster_ca_certificate = module.kube.cluster_ca_certificate
  token                  = data.yandex_client_config.this.iam_token
  load_config_file       = false
}

data "http" "cert-manager-crd" {
  url = "https://github.com/cert-manager/cert-manager/releases/download/v1.12.16/cert-manager.crds.yaml"
}

data "kubectl_file_documents" "docs" {
  content = data.http.cert-manager-crd.response_body
}

//https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs#installation
resource "kubectl_manifest" "cert-manager-crd" {
  for_each  = data.kubectl_file_documents.docs.manifests
  yaml_body = each.value
  depends_on = [module.kube]
}

//example via terraform https://github.com/cert-manager/cert-manager/issues/7369
resource "helm_release" "jetstack" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "v1.12.16"
  depends_on = [
    kubectl_manifest.cert-manager-crd,
    module.kube.node_groups
  ]
  create_namespace = true
  wait             = true
  replace          = true
  timeout          = 90
  #not works
  set {
    name  = "crds.enabled"
    value = true
  }

  set {
    name  = "crds.keep"
    value = false
  }
}

resource "helm_release" "rancher" {
  #  depends_on       = [helm_release.cert-manager, time_sleep.wait_for_cert_manager]
  depends_on = [
    helm_release.jetstack
  ]

  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/stable"
  chart            = "rancher"
  version          = "v2.10.3"
  namespace        = "cattle-system"
  create_namespace = true
  wait             = true
  replace          = true
  timeout          = 600

  set {
    name  = "hostname"
    value = "rancher-yc.zerotech.ru"
  }

  /*set {
    name  = "antiAffinity"
    value = length(var.cluster_nodes) == 1 ? "preffered" : "required"
  }*/
  set {
    name  = "ingress.ingressClassName"
    value = "nginx"
  }

  set {
    name  = "replicas"
    value = "-1"
  }

  set {
    name  = "bootstrapPassword"
    value = "4HEDlokuRcA6elqt"
  }

  //set-string ingress.extraAnnotations.'nginx\.ingress\.kubernetes\.io/ssl-redirect'="false"
}