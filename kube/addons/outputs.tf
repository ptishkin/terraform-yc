output "ingress_nginx_status" {
  value       = module.addons.ingress_nginx_status
  description = "status of ingress"
  sensitive   = true
}
