remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    region = "ru-central1"
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "yds-terraform-state-backend"
    //dynamodb_table = "yds-terraform-state-locks"
    use_lockfile                = true
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true # This option is required for Terraform 1.6.1 or higher.
    skip_metadata_api_check     = true
    //skip_s3_checksum            = true # This option is required to describe a backend for Terraform version 1.6.3 or higher.
    //encrypt                     = true

    key = "${path_relative_to_include()}/terraform.tfstate"
  }
}

locals {
  yds_region       = "ru-central1-b"
  state_bucket     = "yds-terraform-state-backend"
  ydb_table        = "yds-terraform-state-locks"
  ydb_database     = "ydb-serverless"
  cloud_id         = "SOME_ID"
  folder_id        = "b1gsjjo950i2c5fs82pe"
  sa_key_file      = "${get_repo_root()}/key.json"
  endpoint         = "api.yandexcloud.kz:443" # Region-Specific
  storage_endpoint = "storage.yandexcloud.kz" # Region-Specific

  base_versions = read_terragrunt_config(find_in_parent_folders("versions.hcl"), { locals : {} })
  sub_versions  = read_terragrunt_config("versions.hcl", { locals : {} })

  # Merge the providers from root and project-specific versions.hcl files, prioritizing the project-specific versions
  versions = {
    for provider, config in merge(
      lookup(local.sub_versions.locals, "required_providers", {}),
      lookup(local.base_versions.locals, "required_providers", {})
    ) :
    provider => {
      source  = lookup(config, "source", null)
      version = lookup(config, "version", ">= 0")
    }
    #if lookup(config, "version", null) != null
  }

  # Use the required_version from the project-specific versions.hcl file if defined, otherwise use the one from the root versions.hcl file
  required_version = coalesce(
    lookup(local.sub_versions.locals, "required_version", ""),
    lookup(local.base_versions.locals, "required_version", "")
  )
}

generate "versions" {
  //path      = "../../${path_relative_to_include("root")}/versions.tf"
  path      = "versions.tf"
  if_exists = "overwrite"

  contents = <<EOF
terraform {
  required_version = "${local.required_version}"

  required_providers {
    %{for provider, config in local.versions}
    ${provider} = {
      source  = "${config.source}"
      version = "${config.version}"
    }
    %{endfor}
  }
}
EOF
}

generate "variables" {
  path      = "variables.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "yds_region" {
  type        = string
  description = "Yandex region"
  default     = "ru-central1-b"
}

variable "state_bucket" {
  type        = string
  description = "S3 bucket for holding Terraform state files. Must be globally unique"
  default     = "yds-terraform-state-backend"
}

variable "ydb_table" {
  type        = string
  description = "ydb table for locking Terraform states"
  default     = "yds-terraform-state-locks"
}

variable "ydb_database" {
  type        = string
  description = "ydb database for storing ydb tables"
  default     = "ydb-serverless"
}

variable "folder_id" {
  type        = string
  description = "s3 storage forder"
  default     = "b1gsjjo950i2c5fs82pe"
}

EOF
}
