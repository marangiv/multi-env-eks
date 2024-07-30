# This file defines all the variables used in the Terraform configuration

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

variable "user_arn" {
  description = "The ARN of the IAM user to add to the aws-auth ConfigMap"
  type        = string
}

variable "user_name" {
  description = "The username to map the IAM user to in the aws-auth ConfigMap"
  type        = string
}

variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
}

# New variables for EC2 node groups

variable "node_group_instance_types" {
  description = "List of EC2 instance types for the EKS node groups"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes in each EKS node group"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes in each EKS node group"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes in each EKS node group"
  type        = number
  default     = 3
}

variable "node_group_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

variable "node_group_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  type        = string
  default     = "AL2_x86_64"  # Amazon Linux 2 AMI
}