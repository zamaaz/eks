output "eks_cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API server."
  value       = aws_eks_cluster.default.endpoint
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.default.name
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster."
  value       = aws_eks_cluster.default.arn
}
