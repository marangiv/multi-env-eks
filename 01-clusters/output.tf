output "cluster_names" {
  description = "Names of the EKS clusters"
  value = {
    us-west-2 = module.eks_us_west_2.cluster_name
    us-east-1 = module.eks_us_east_1.cluster_name
    eu-west-1 = module.eks_eu_west_1.cluster_name
  }
}

output "cluster_endpoints" {
  description = "Endpoints for the EKS clusters"
  value = {
    us-west-2 = module.eks_us_west_2.cluster_endpoint
    us-east-1 = module.eks_us_east_1.cluster_endpoint
    eu-west-1 = module.eks_eu_west_1.cluster_endpoint
  }
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the clusters"
  value = {
    us-west-2 = module.eks_us_west_2.cluster_certificate_authority_data
    us-east-1 = module.eks_us_east_1.cluster_certificate_authority_data
    eu-west-1 = module.eks_eu_west_1.cluster_certificate_authority_data
  }
}

# Output the VPC IDs for each region
output "vpc_ids" {
  description = "Map of VPC IDs"
  value = {
    us-west-2 = module.vpc_us_west_2.vpc_id
    us-east-1 = module.vpc_us_east_1.vpc_id
    eu-west-1 = module.vpc_eu_west_1.vpc_id
  }
}

# Output the kubectl configurations for each cluster
output "kubectl_configs" {
  description = "kubectl configs for each cluster"
  value = {
    us-west-2 = module.eks_us_west_2.kubectl_config
    us-east-1 = module.eks_us_east_1.kubectl_config
    eu-west-1 = module.eks_eu_west_1.kubectl_config
  }
  // sensitive = true
}