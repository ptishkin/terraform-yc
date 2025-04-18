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
  zone = var.yds_region
}

resource "yandex_ydb_database_serverless" "database_serverless" {
  name                = var.ydb_database
  deletion_protection = true

  serverless_database {
    enable_throttling_rcu_limit = false
    provisioned_rcu_limit       = 10
    storage_size_limit          = 50
    throttling_rcu_limit        = 0
  }
}

resource "yandex_iam_service_account" "terraform_state_sa" {
  folder_id = var.folder_id
  name      = "terraform-state-sa"
}

resource "yandex_iam_service_account_static_access_key" "terraform_state_sa-static-key" {
  service_account_id = yandex_iam_service_account.terraform_state_sa.id
  description        = "static access key for object storage"
}

// Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "terraform_state_sa-editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_state_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "terraform_state_sa-dbadmin" {
  folder_id = var.folder_id
  role      = "ydb.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_state_sa.id}"
}
