# variable "cluster_name" {
#   description = "The name of the EKS cluster"
#   type        = string
# }

# variable "oidc_provider_arn" {
#   description = "The OIDC provider ARN"
#   type        = string
# }

# variable "cluster_id" {
#   description = "The EKS cluster ID"
#   type        = string
# }
variable "environment" {
  description = "The environment for the resources"
  type        = string
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
