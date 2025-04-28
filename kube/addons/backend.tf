terraform {
  backend "s3" {
    region = "ru-central1"
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    bucket = "yds-terraform-state-backend"
    //dynamodb_table = "yds-terraform-state-locks"
    use_lockfile                = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true # This option is required for Terraform 1.6.1 or higher.
    skip_metadata_api_check     = true
    //skip_s3_checksum            = true # This option is required to describe a backend for Terraform version 1.6.3 or higher.
    //encrypt                     = true

    key = "kube/addons/terraform.tfstate"
  }
}
