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

# Module for US West 2
module "autoscaler_us_west_2" {
  source           = "../modules/autoscaler"
  cluster_name     = data.aws_eks_cluster.eks_us_west_2.name
  oidc_provider_arn = data.aws_eks_cluster.eks_us_west_2.identity[0].oidc[0].issuer
  cluster_id       = data.aws_eks_cluster.eks_us_west_2.id
}

# Module for US East 1
module "autoscaler_us_east_1" {
  source           = "../modules/autoscaler"
  cluster_name     = data.aws_eks_cluster.eks_us_east_1.name
  oidc_provider_arn = data.aws_eks_cluster.eks_us_east_1.identity[0].oidc[0].issuer
  cluster_id       = data.aws_eks_cluster.eks_us_east_1.id
}

# Module for EU West 1
module "autoscaler_eu_west_1" {
  source           = "../modules/autoscaler"
  cluster_name     = data.aws_eks_cluster.eks_eu_west_1.name
  oidc_provider_arn = data.aws_eks_cluster.eks_eu_west_1.identity[0].oidc[0].issuer
  cluster_id       = data.aws_eks_cluster.eks_eu_west_1.id
}
