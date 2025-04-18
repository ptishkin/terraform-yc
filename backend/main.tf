#https://developer.hashicorp.com/terraform/language/backend/s3#s3-1
#https://yandex.cloud/en/docs/tutorials/infrastructure-management/terraform-state-lock#create-service-account
#https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-state-storage
terraform {
  /*backend "s3" {
    region = "ru-central1"
    endpoints {
      s3       = "https://storage.yandexcloud.net"
      dynamodb = "https://docapi.serverless.yandexcloud.net/ru-central1/b1g4aoclmf5bfpmghgju/etnj3a411gcr4ac2tnr1"
    }

    bucket         = "yds-terraform-state-backend"
    key            = "backend/terraform.tfstate"
    dynamodb_table = "yds-terraform-state-locks"
    //access_key                  = data.terraform_remote_state.ydb.outputs.sa_access_key
    //secret_key                  = data.terraform_remote_state.ydb.outputs.sa_secret_key
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true # This option is required for Terraform 1.6.1 or higher.
    skip_s3_checksum            = true # This option is required to describe a backend for Terraform version 1.6.3 or higher.
    //encrypt                     = true
  }*/

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

data "yandex_client_config" "this" {}

//https://developer.hashicorp.com/terraform/language/state/remote-state-data
data "terraform_remote_state" "ydb" {
  backend = "local"
  config = {
    path = "ydb/terraform.tfstate"
  }
}

provider "aws" {
  region = "ru-central1"
  endpoints {
    s3       = "https://storage.yandexcloud.net"
    dynamodb = data.terraform_remote_state.ydb.outputs.ydb_full_endpoint
  }
  access_key                  = data.terraform_remote_state.ydb.outputs.sa_access_key
  secret_key                  = data.terraform_remote_state.ydb.outputs.sa_secret_key
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

resource "yandex_storage_bucket" "terraform_state" {
  access_key = data.terraform_remote_state.ydb.outputs.sa_access_key
  secret_key = data.terraform_remote_state.ydb.outputs.sa_secret_key
  bucket     = var.state_bucket
}
/*resource "yandex_storage_object" "s3_access_block" {
  bucket = yandex_storage_bucket.terraform_state.id

}*/

/*resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  object_lock_configuration {
    object_lock_enabled = "Enabled"
  }
  lifecycle {
    prevent_destroy = true
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
