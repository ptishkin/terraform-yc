output "s3_bucket_id" {
  value       = yandex_storage_bucket.terraform_state.id
  description = "The name of S3 bucket"
  sensitive   = true
}
