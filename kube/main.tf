#https://github.com/terraform-yc-modules/terraform-yc-kubernetes/blob/master/variables.tf
terraform {
  backend "s3" {
    region = "ru-central1"
    endpoints = {
      s3       = "https://storage.yandexcloud.net"
      dynamodb = "https://docapi.serverless.yandexcloud.net/ru-central1/b1g4aoclmf5bfpmghgju/etnj3a411gcr4ac2tnr1"
    }
    bucket                      = "yds-terraform-state-backend"
    key                         = "kube/terraform.tfstate"
    dynamodb_table              = "yds-terraform-state-locks"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true # This option is required for Terraform 1.6.1 or higher.
    skip_s3_checksum            = true # This option is required to describe a backend for Terraform version 1.6.3 or higher.
    //encrypt                     = true
  }

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = var.yds_region
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = "ru-central1"
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket                      = "yds-terraform-state-backend"
    key                         = "vpc/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true # This option is required for Terraform 1.6.1 or higher.
    skip_s3_checksum            = true # This option is required to describe a backend for Terraform version 1.6.3 or higher.
  }
}

module "kube" {
  source     = "github.com/terraform-yc-modules/terraform-yc-kubernetes.git"
  network_id = data.terraform_remote_state.vpc.outputs.vpc_id

  master_locations = [
    for s in data.terraform_remote_state.vpc.outputs.private_subnets :
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
