# Admin kubeconfig uploaded to S3. It holds no secrets: it logs in with
# `aws eks get-token` using the admin's own AWS credentials.
# Download: terraform output -raw kubeconfig_download_command
locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = aws_eks_cluster.eks.name
    clusters = [{
      name = aws_eks_cluster.eks.name
      cluster = {
        server                     = aws_eks_cluster.eks.endpoint
        certificate-authority-data = aws_eks_cluster.eks.certificate_authority[0].data
      }
    }]
    contexts = [{
      name = aws_eks_cluster.eks.name
      context = {
        cluster = aws_eks_cluster.eks.name
        user    = aws_eks_cluster.eks.name
      }
    }]
    users = [{
      name = aws_eks_cluster.eks.name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args       = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks.name, "--region", var.aws_region]
        }
      }
    }]
  })
}

resource "aws_s3_object" "kubeconfig" {
  bucket                 = var.kubeconfig_bucket
  key                    = var.kubeconfig_s3_key
  content                = local.kubeconfig
  content_type           = "application/yaml"
  server_side_encryption = "AES256"
}
