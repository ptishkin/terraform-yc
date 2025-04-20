output "service_loadbalancer_ip" {
  value       = module.addons.ingress_nginx.service_loadbalancer_ip
  description = "The LB IP of the kuber"
  sensitive   = true
}
