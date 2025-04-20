output "external_v4_endpoint" {
  value       = module.kube.external_v4_endpoint
  description = "The kube api endpoint"
  sensitive   = true
}

output "cluster_ca_certificate" {
  value       = module.kube.cluster_ca_certificate
  description = "The kube ca cert"
  sensitive   = true
}

output "cluster_id" {
  value       = module.kube.cluster_id
  description = "The kube cluster_id"
}
