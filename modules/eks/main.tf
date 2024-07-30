# This file defines the EKS cluster and its node groups

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Use the official AWS EKS module to create and manage the EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  # Basic cluster configuration
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Networking configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  # Configure managed node groups for EC2 instances
  eks_managed_node_groups = {
    # Node group for system components (kube-system)
    system = {
      name           = "system-ng"
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      labels = {
        "node-type" = "system"
      }
      # Taint to ensure only system pods are scheduled here
      taints = [
        {
          key    = "dedicated"
          value  = "system"
          effect = "NO_SCHEDULE"
        }
      ]
    }

    # Node group for argocd components
    argocd = {
      name           = "argocd"
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      labels = {
        "node-type" = "argocd"
      }
    }
  }

  # Enable EKS Managed Add-ons for essential cluster components
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  # Enable IAM roles for service accounts (IRSA)
  enable_irsa = true

  # Add tags for better resource management and identification
  tags = {
    Environment = var.environment
    Region      = var.region
    Terraform   = "true"
  }
}

# # Create IAM policy for cluster autoscaler
# resource "aws_iam_policy" "cluster_autoscaler" {
#   name        = "${var.cluster_name}-cluster-autoscaler"
#   path        = "/"
#   description = "EKS cluster-autoscaler policy for cluster ${var.cluster_name}"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "autoscaling:DescribeAutoScalingGroups",
#           "autoscaling:DescribeAutoScalingInstances",
#           "autoscaling:DescribeLaunchConfigurations",
#           "autoscaling:DescribeTags",
#           "autoscaling:SetDesiredCapacity",
#           "autoscaling:TerminateInstanceInAutoScalingGroup",
#           "ec2:DescribeLaunchTemplateVersions"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#       {
#         Action = [
#           "autoscaling:UpdateAutoScalingGroup",
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster_name != "" ? var.cluster_name : "default-cluster"}" = "owned"
#           }
#         }
#       }
#     ]
#   })
# }

# # Create IAM role for cluster autoscaler
# module "cluster_autoscaler_irsa_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "~> 5.0"

#   role_name                        = "cluster-autoscaler-${var.cluster_name != "" ? var.cluster_name : "default-cluster"}"
#   attach_cluster_autoscaler_policy = true
#   cluster_autoscaler_cluster_ids   = [module.eks.cluster_id]

#   oidc_providers = {
#     ex = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:cluster-autoscaler"]
#     }
#   }
# }


