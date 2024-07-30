# This file defines the input variables for the EKS module

variable "cluster_name" {
  description = "The name of the EKS cluster. Must be unique within your AWS account."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "The ID of the VPC where the EKS cluster will be created."
  type        = string
}

variable "private_subnets" {
  description = "A list of private subnet IDs to launch the EKS cluster in."
  type        = list(string)
}

variable "environment" {
  description = "Environment name, e.g. 'prod', 'staging', 'dev'"
  type        = string
}

variable "region" {
  description = "AWS region where the EKS cluster will be created."
  type        = string
}

variable "cluster_endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type        = any
  default     = {}
}


