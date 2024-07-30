# Define required providers and their versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Use AWS provider version 5.x
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"  # Use Helm provider version 2.x
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"  # Use Kubernetes provider version 2.x
    }
  }
}

# Define AWS provider configurations for each region
# These allow resources to be created in specific regions
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
# This data will be used to configure Kubernetes and Helm providers
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
# These providers will be used to interact with the EKS clusters
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
# These providers will be used to deploy Helm charts to the EKS clusters
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

# Deploy Argo CD using Helm to each EKS cluster
# This sets up Argo CD in each region for GitOps-based deployments
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

# Create a security group for the Application Load Balancer (ALB)
# This security group controls inbound and outbound traffic for the ALB
resource "aws_security_group" "alb" {
  name        = "argocd-alb-sg"
  description = "Security group for ArgoCD ALB"
  vpc_id      = var.vpc_ids["us-west-2"]  # Using us-west-2 as the primary VPC

  # Allow inbound HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "argocd-alb-sg"
  }
}

# Fetch subnet IDs for the ALB
# This data source retrieves all subnet IDs in the specified VPC
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_ids["us-west-2"]]  # Using us-west-2 as the primary VPC
  }
}

# Create the Application Load Balancer (ALB)
# This ALB will distribute traffic across the Argo CD instances in different regions
resource "aws_lb" "argocd" {
  name               = "argocd-lb"
  internal           = false  # Internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.selected.ids

  enable_deletion_protection = false

  tags = {
    Name = "argocd-lb"
  }
}

# Fetch VPC data for each region
# This data will be used to create target groups in each VPC
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

# Create target groups for each region
# These target groups will be used by the ALB to route traffic to the Argo CD instances
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

# Create an ALB Listener
# This listener routes incoming traffic to the appropriate target group
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

# Note: This configuration sets up a multi-region Argo CD deployment with a single ALB.
# Consider adding HTTPS support and AWS Certificate Manager for production use.
# Also, you may want to add Route53 records for DNS management.