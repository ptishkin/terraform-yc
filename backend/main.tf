#https://developer.hashicorp.com/terraform/language/backend/s3#s3-1
#https://yandex.cloud/en/docs/tutorials/infrastructure-management/terraform-state-lock#create-service-account
#https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-state-storage
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

    key = "backend/terraform.tfstate"
  }

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 0.13"
}

//https://developer.hashicorp.com/terraform/language/state/remote-state-data
/*data "terraform_remote_state" "ydb" {
  backend = "local"
  config = {
    path = "ydb/terraform.tfstate"
  }
}*/

provider "aws" {
  region = "ru-central1"
  endpoints {
    s3 = "https://storage.yandexcloud.net"
  }
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

provider "yandex" {
  folder_id = var.folder_id
  zone      = var.yds_region
}

//https://yandex.cloud/ru/docs/ydb/terraform/dynamodb-tables
resource "aws_dynamodb_table" "terraform_state_locks" {
  name         = var.ydb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

// Use keys to create bucket
resource "yandex_kms_symmetric_key" "key-a" {
  name              = "example-symetric-key"
  description       = "description for key"
  default_algorithm = "AES_256"
  rotation_period   = "87600h" // equal to 1 year
}

resource "yandex_storage_bucket" "terraform_state" {
  bucket = var.state_bucket

  acl = "private"

  versioning {
    enabled = true
  }

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }

  lifecycle {
    prevent_destroy = false
  }

  object_lock_configuration {
    object_lock_enabled = "Enabled"
  }

  /*server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = yandex_kms_symmetric_key.key-a.id
      }
    }
  }*/
}
/*
resource "yandex_storage_object" "s3_access_block" {
  bucket = yandex_storage_bucket.terraform_state.id

}*/
/*
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        //sse_algorithm = "AES256"
        sse_algorithm = "aws:kms"
      }
    }
  }

  object_lock_configuration {
    object_lock_enabled = "Enabled"
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access_block" {
  depends_on              = [aws_s3_bucket.terraform_state]
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}*/
