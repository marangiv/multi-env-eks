output "alb_dns_name" {
  description = "DNS name of the ALB for Argo CD"
  value       = aws_lb.argocd.dns_name
}
