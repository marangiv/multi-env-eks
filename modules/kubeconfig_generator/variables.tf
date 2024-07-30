variable "us_west_2_cluster_name" {}
variable "us_west_2_endpoint" {}
variable "us_west_2_cert_auth_data" {}

variable "us_east_1_cluster_name" {}
variable "us_east_1_endpoint" {}
variable "us_east_1_cert_auth_data" {}

variable "eu_west_1_cluster_name" {}
variable "eu_west_1_endpoint" {}
variable "eu_west_1_cert_auth_data" {}

variable "us_west_2_kubectl_config" {
  description = "kubectl config for us-west-2 cluster"
  type        = string
}

variable "us_east_1_kubectl_config" {
  description = "kubectl config for us-east-1 cluster"
  type        = string
}

variable "eu_west_1_kubectl_config" {
  description = "kubectl config for eu-west-1 cluster"
  type        = string
}