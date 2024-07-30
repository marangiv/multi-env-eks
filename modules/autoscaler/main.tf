# Create IAM policy for cluster autoscaler
resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${var.cluster_name}-cluster-autoscaler"
  path        = "/"
  description = "EKS cluster-autoscaler policy for cluster ${var.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          StringEquals = {
            "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster_name != "" ? var.cluster_name : "default-cluster"}" = "owned"
          }
        }
      }
    ]
  })
}

# Create IAM role for cluster autoscaler
module "cluster_autoscaler_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                        = "cluster-autoscaler-${var.cluster_name != "" ? var.cluster_name : "default-cluster"}"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [var.cluster_id]

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}
