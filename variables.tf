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
