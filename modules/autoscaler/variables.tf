variable "cluster_name" {
  description = "The name of the EKS cluster. Must be unique within your AWS account."
  type        = string
}

variable "oidc_provider_arn" {
  description = "The OIDC provider ARN"
  type        = string
}

variable "cluster_id" {
  description = "The EKS cluster ID"
  type        = string
}
