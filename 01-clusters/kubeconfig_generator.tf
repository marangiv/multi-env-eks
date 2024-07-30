module "kubeconfig_generator" {
  source = "../modules/kubeconfig_generator"

  depends_on = [
    module.eks_us_west_2,
    module.eks_us_east_1,
    module.eks_eu_west_1
  ]

  us_west_2_cluster_name = module.eks_us_west_2.cluster_name
  us_west_2_endpoint     = module.eks_us_west_2.cluster_endpoint
  us_west_2_cert_auth_data = module.eks_us_west_2.cluster_certificate_authority_data
  us_west_2_kubectl_config = module.eks_us_west_2.kubectl_config
  
  us_east_1_cluster_name = module.eks_us_east_1.cluster_name
  us_east_1_endpoint     = module.eks_us_east_1.cluster_endpoint
  us_east_1_cert_auth_data = module.eks_us_east_1.cluster_certificate_authority_data
  us_east_1_kubectl_config = module.eks_us_east_1.kubectl_config

  eu_west_1_cluster_name = module.eks_eu_west_1.cluster_name
  eu_west_1_endpoint     = module.eks_eu_west_1.cluster_endpoint
  eu_west_1_cert_auth_data = module.eks_eu_west_1.cluster_certificate_authority_data
  eu_west_1_kubectl_config = module.eks_eu_west_1.kubectl_config
}