output "ydb_full_endpoint" {
  description = "database connection string"
  value       = yandex_ydb_database_serverless.database_serverless.document_api_endpoint
}

output "sa_access_key" {
  value       = yandex_iam_service_account_static_access_key.terraform_state_sa-static-key.access_key
  description = "The name of S3 bucket"
  sensitive   = true
}

output "sa_secret_key" {
  value       = yandex_iam_service_account_static_access_key.terraform_state_sa-static-key.secret_key
  description = "The name of S3 bucket"
  sensitive   = true
}
