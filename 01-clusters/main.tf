                                                      
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Defining AWS providers for each region.
# Each provider has a unique alias that we will use to refer to it.
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
                                               
locals {
  cluster_names = {
    for region in var.regions :
    region => "eks-${var.environment}-${region}"
  }
}

# VPC module for the us-west-2 region.
module "vpc_us_west_2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.9"

  name = "vpc-${var.environment}-us-west-2"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.environment
    Region      = "us-west-2"
  }

  # We specify which AWS provider to use for this module.
  providers = {
    aws = aws.us-west-2
  }
}

# EKS module for the us-west-2 region.
module "eks_us_west_2" {
  source = "../modules/eks"

  cluster_name    = "eks-${var.environment}-us-west-2"
  cluster_version = var.cluster_version
  vpc_id          = module.vpc_us_west_2.vpc_id
  private_subnets = module.vpc_us_west_2.private_subnets

  environment = var.environment
  region      = "us-west-2"

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  cluster_addons = var.cluster_addons

# We specify which AWS provider to use for this module.
  providers = {
    aws = aws.us-west-2
  }
}

# VPC module for the us-east-1 region.
module "vpc_us_east_1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.9"

  name = "vpc-${var.environment}-us-east-1"
  cidr = "10.1.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.environment
    Region      = "us-east-1"
  }

  providers = {
    aws = aws.us-east-1
  }
}

# EKS module for the us-east-1 region.
module "eks_us_east_1" {
  source = "../modules/eks"

  cluster_name    = "eks-${var.environment}-us-east-1"
  cluster_version = var.cluster_version
  vpc_id          = module.vpc_us_east_1.vpc_id
  private_subnets = module.vpc_us_east_1.private_subnets

  environment = var.environment
  region      = "us-east-1"

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  cluster_addons = var.cluster_addons

  providers = {
    aws = aws.us-east-1
  }
}

# VPC module for eu-west-1 region.
module "vpc_eu_west_1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.9"

  name = "vpc-${var.environment}-eu-west-1"
  cidr = "10.2.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnets  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.environment
    Region      = "eu-west-1"
  }

  providers = {
    aws = aws.eu-west-1
  }
}

# EKS module for the eu-west-1 region.
module "eks_eu_west_1" {
  source = "../modules/eks"

  cluster_name    = "eks-${var.environment}-eu-west-1"
  cluster_version = var.cluster_version
  vpc_id          = module.vpc_eu_west_1.vpc_id
  private_subnets = module.vpc_eu_west_1.private_subnets

  environment = var.environment
  region      = "eu-west-1"

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  cluster_addons = var.cluster_addons

  providers = {
    aws = aws.eu-west-1
  }
}