output "vpc_id" {
  value       = module.yc-vpc.vpc_id
  description = "The Id of the VPC"
}

/*output "vpc_cidr_block" {
  value       = module.yc-vpc.vpc_cidr_block
  description = "The CIDR block of the VPC"
}*/

output "private_subnets" {
  value       = module.yc-vpc.private_subnets
  description = "List of Id private subnets"
}

output "public_subnets" {
  value       = module.yc-vpc.public_subnets
  description = "List of Id public subnets"
}
