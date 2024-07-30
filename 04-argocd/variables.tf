variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_names" {
  description = "Names of the EKS clusters"
  type        = map(string)
}

variable "cluster_us_west_2_name" {
  description = "The name of the EKS cluster in us-west-2"
  type        = string
}

variable "cluster_us_east_1_name" {
  description = "The name of the EKS cluster in us-east-1"
  type        = string
}

variable "cluster_eu_west_1_name" {
  description = "The name of the EKS cluster in eu-west-1"
  type        = string
}
variable "cluster_endpoints" {
  description = "Endpoints for the EKS clusters"
  type        = map(string)
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the clusters"
  type        = map(string)
}

variable "vpc_ids" {
  description = "Map of VPC IDs for each region"
  type        = map(string)
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "subnets" {
  description = "Subnets for the ALB"
  type        = list(string)
}

variable "argocd_chart_version" {
  description = "Version of the Argo CD Helm chart to install"
  type        = string
  default     = "5.34.1"
}