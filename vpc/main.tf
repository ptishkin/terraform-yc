#https://github.com/terraform-yc-modules/terraform-yc-kubernetes/blob/master/variables.tf
terraform {
  backend "s3" {
    region = "ru-central1"
    endpoints = {
      s3       = "https://storage.yandexcloud.net"
      dynamodb = "https://docapi.serverless.yandexcloud.net/ru-central1/b1g4aoclmf5bfpmghgju/etnj3a411gcr4ac2tnr1"
    }
    bucket                      = "yds-terraform-state-backend"
    key                         = "vpc/terraform.tfstate"
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
