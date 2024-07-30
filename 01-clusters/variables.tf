# This file defines the input variables for the root module

variable "environment" {
  description = "Environment name, e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "regions" {
  description = "List of AWS regions to deploy to"
  type        = list(string)
  default     = ["us-west-2", "us-east-1", "eu-west-1"]
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS clusters"
  type        = string
  default     = "1.30"
}

variable "cluster_endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the clusters"
  type        = any
  default     = {}
}
