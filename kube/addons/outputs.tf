output "service_loadbalancer_ip" {
  value       = module.addons.ingress_nginx_status
  description = "The LB IP of the kuber"
  sensitive   = true
}
