#https://github.com/terraform-yc-modules/terraform-yc-kubernetes/blob/master/variables.tf
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
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