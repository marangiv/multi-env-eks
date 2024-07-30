terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
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

# Configure Helm Providers for each region
provider "helm" {
  alias = "us_west_2"
  kubernetes {
    host                   = data.aws_eks_cluster.eks_us_west_2.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_us_west_2.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks_us_west_2.token
  }
}

provider "helm" {
  alias = "us_east_1"
  kubernetes {
    host                   = data.aws_eks_cluster.eks_us_east_1.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_us_east_1.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks_us_east_1.token
  }
}

provider "helm" {
  alias = "eu_west_1"
  kubernetes {
    host                   = data.aws_eks_cluster.eks_eu_west_1.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_eu_west_1.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks_eu_west_1.token
  }
}

# locals {
#   clusters = {
#     us_west_2 = var.cluster_us_west_2_name
#     us_east_1 = var.cluster_us_east_1_name
#     eu_west_1 = var.cluster_eu_west_1_name
#   }
# }

# Argo CD Helm Releases
resource "helm_release" "argocd_us_west_2" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = var.argocd_chart_version

  provider = helm.us_west_2
}

resource "helm_release" "argocd_us_east_1" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = var.argocd_chart_version

  provider = helm.us_east_1
}

resource "helm_release" "argocd_eu_west_1" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = var.argocd_chart_version

  provider = helm.eu_west_1
}

resource "aws_lb" "argocd" {
  name               = "argocd-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnets

  enable_deletion_protection = false
}


# Target Groups
# Data sources per i VPC
data "aws_vpc" "us_west_2" {
  provider = aws.us-west-2
  id       = var.vpc_ids["us-west-2"]
}

data "aws_vpc" "us_east_1" {
  provider = aws.us-east-1
  id       = var.vpc_ids["us-east-1"]
}

data "aws_vpc" "eu_west_1" {
  provider = aws.eu-west-1
  id       = var.vpc_ids["eu-west-1"]
}

# Target Groups
resource "aws_lb_target_group" "argocd_us_west_2" {
  provider    = aws.us-west-2
  name        = "argocd-tg-${var.environment}-us-west-2"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.us_west_2.id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    port                = 8080
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "argocd_us_east_1" {
  provider    = aws.us-east-1
  name        = "argocd-tg-${var.environment}-us-east-1"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.us_east_1.id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    port                = 8080
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "argocd_eu_west_1" {
  provider    = aws.eu-west-1
  name        = "argocd-tg-${var.environment}-eu-west-1"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.eu_west_1.id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    port                = 8080
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# ALB Listener
resource "aws_lb_listener" "argocd" {
  load_balancer_arn = aws_lb.argocd.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.argocd_us_west_2.arn
        weight = 1
      }
      target_group {
        arn    = aws_lb_target_group.argocd_us_east_1.arn
        weight = 1
      }
      target_group {
        arn    = aws_lb_target_group.argocd_eu_west_1.arn
        weight = 1
      }
    }
  }
}