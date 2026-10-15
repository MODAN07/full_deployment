# =============================================================================
# All outputs in one place. Show them with: terraform output
# =============================================================================

# ---- EKS ----
output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_version" {
  value = aws_eks_cluster.eks.version
}

output "eks_node_group_name" {
  value = aws_eks_node_group.node_group.node_group_name
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.eks.name}"
}

# ---- kubeconfig in S3 ----
output "kubeconfig_s3_uri" {
  value = "s3://${aws_s3_object.kubeconfig.bucket}/${aws_s3_object.kubeconfig.key}"
}

output "kubeconfig_download_command" {
  value = "aws s3 cp s3://${aws_s3_object.kubeconfig.bucket}/${aws_s3_object.kubeconfig.key} ~/.kube/config"
}

# ---- Ingress ----
output "load_balancer_hostname" {
  description = "Point a CNAME record for your domain at this hostname"
  value       = data.kubernetes_service_v1.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname
}

# ---- Argo CD ----
output "argocd_url" {
  value = "https://${var.argocd_hostname}"
}

output "argocd_admin_username" {
  value = "admin"
}

output "argocd_initial_admin_password" {
  value     = data.kubernetes_secret_v1.argocd_initial_admin.data["password"]
  sensitive = true
}

# ---- EFS ----
output "efs_file_system_id" {
  value = aws_efs_file_system.efs.id
}

output "efs_storage_class" {
  value = kubernetes_storage_class_v1.efs.metadata[0].name
}
