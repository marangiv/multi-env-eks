#Output the IAM role ARN for cluster autoscaler
output "cluster_autoscaler_iam_role_arn" {
  description = "IAM role ARN for cluster autoscaler"
  value       = module.cluster_autoscaler_irsa_role.iam_role_arn
}

