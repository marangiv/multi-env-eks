# This file contains the main Terraform configuration for managing EKS clusters across multiple regions

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Define AWS providers for each region
provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu-west-1"
  region = "eu-west-1"
}

# Fetch EKS cluster data for each region
data "aws_eks_cluster" "eks_us_west_2" {
  provider = aws.us-west-2
  name     = var.cluster_us_west_2_name
}

data "aws_eks_cluster_auth" "eks_us_west_2" {
  provider = aws.us-west-2
  name     = var.cluster_us_west_2_name
}

data "aws_eks_cluster" "eks_us_east_1" {
  provider = aws.us-east-1
  name     = var.cluster_us_east_1_name
}

data "aws_eks_cluster_auth" "eks_us_east_1" {
  provider = aws.us-east-1
  name     = var.cluster_us_east_1_name
}

data "aws_eks_cluster" "eks_eu_west_1" {
  provider = aws.eu-west-1
  name     = var.cluster_eu_west_1_name
}

data "aws_eks_cluster_auth" "eks_eu_west_1" {
  provider = aws.eu-west-1
  name     = var.cluster_eu_west_1_name
}

# Configure Kubernetes providers for each region
provider "kubernetes" {
  alias                  = "us_west_2"
  host                   = data.aws_eks_cluster.eks_us_west_2.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_us_west_2.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_us_west_2.token
}

provider "kubernetes" {
  alias                  = "us_east_1"
  host                   = data.aws_eks_cluster.eks_us_east_1.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_us_east_1.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_us_east_1.token
}

provider "kubernetes" {
  alias                  = "eu_west_1"
  host                   = data.aws_eks_cluster.eks_eu_west_1.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_eu_west_1.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_eu_west_1.token
}

locals {
  clusters = {
    us_west_2 = var.cluster_us_west_2_name
    us_east_1 = var.cluster_us_east_1_name
    eu_west_1 = var.cluster_eu_west_1_name
  }
}

# Create cluster role bindings for admin access in each region
resource "kubernetes_cluster_role_binding" "eks_admin_binding_us_west_2" {
  provider = kubernetes.us_west_2
  metadata {
    name = "eks-admin-binding-us-west-2"
  }
  subject {
    kind      = "User"
    name      = var.user_name
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role_binding" "eks_admin_binding_us_east_1" {
  provider = kubernetes.us_east_1
  metadata {
    name = "eks-admin-binding-us-east-1"
  }
  subject {
    kind      = "User"
    name      = var.user_name
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role_binding" "eks_admin_binding_eu_west_1" {
  provider = kubernetes.eu_west_1
  metadata {
    name = "eks-admin-binding-eu-west-1"
  }
  subject {
    kind      = "User"
    name      = var.user_name
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

# Fetch existing aws-auth ConfigMap data for each region
data "kubernetes_config_map" "aws_auth_us_west_2" {
  provider = kubernetes.us_west_2
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

data "kubernetes_config_map" "aws_auth_us_east_1" {
  provider = kubernetes.us_east_1
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

data "kubernetes_config_map" "aws_auth_eu_west_1" {
  provider = kubernetes.eu_west_1
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

# Prepare updated mapUsers data for aws-auth ConfigMap
locals {
  existing_map_users = {
    us_west_2 = yamldecode(lookup(data.kubernetes_config_map.aws_auth_us_west_2.data, "mapUsers", "[]"))
    us_east_1 = yamldecode(lookup(data.kubernetes_config_map.aws_auth_us_east_1.data, "mapUsers", "[]"))
    eu_west_1 = yamldecode(lookup(data.kubernetes_config_map.aws_auth_eu_west_1.data, "mapUsers", "[]"))
  }
  new_map_users = {
    for k, v in local.existing_map_users : k => distinct(concat(v, [
      {
        userarn  = var.user_arn
        username = var.user_name
        groups   = ["system:masters"]
      }
    ]))
  }
}

# Update aws-auth ConfigMap in each region
resource "kubernetes_config_map_v1_data" "aws_auth_update_us_west_2" {
  provider = kubernetes.us_west_2
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapUsers = yamlencode(local.new_map_users["us_west_2"])
  }
  force = true
}

resource "kubernetes_config_map_v1_data" "aws_auth_update_us_east_1" {
  provider = kubernetes.us_east_1
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapUsers = yamlencode(local.new_map_users["us_east_1"])
  }
  force = true
}

resource "kubernetes_config_map_v1_data" "aws_auth_update_eu_west_1" {
  provider = kubernetes.eu_west_1
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapUsers = yamlencode(local.new_map_users["eu_west_1"])
  }
  force = true
}

# Define IAM policy for EKS access
data "aws_iam_policy_document" "eks_access" {
  statement {
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:AccessKubernetesApi",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVpcs",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]
    resources = ["*"]
  }
}

# Attach EKS access policy to IAM user
resource "aws_iam_user_policy" "eks_access" {
  provider = aws.us-west-2
  name     = "eks-access"
  user     = var.user_name
  policy   = data.aws_iam_policy_document.eks_access.json
}

# Output updated aws-auth ConfigMap data
output "aws_auth_map_users" {
  value = {
    us_west_2 = yamldecode(kubernetes_config_map_v1_data.aws_auth_update_us_west_2.data.mapUsers)
    us_east_1 = yamldecode(kubernetes_config_map_v1_data.aws_auth_update_us_east_1.data.mapUsers)
    eu_west_1 = yamldecode(kubernetes_config_map_v1_data.aws_auth_update_eu_west_1.data.mapUsers)
  }
  description = "The updated mapUsers section of the aws-auth ConfigMap for each region"
}

# Output commands to update kubeconfig
output "update_kubeconfig_commands" {
  value = {
    us_west_2 = "aws eks get-token --cluster-name ${var.cluster_us_west_2_name} --region us-west-2 | kubectl apply -f -"
    us_east_1 = "aws eks get-token --cluster-name ${var.cluster_us_east_1_name} --region us-east-1 | kubectl apply -f -"
    eu_west_1 = "aws eks get-token --cluster-name ${var.cluster_eu_west_1_name} --region eu-west-1 | kubectl apply -f -"
  }
  description = "Commands to update kubeconfig with new credentials"
}
