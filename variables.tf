# ---- General ----
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster; also used as a prefix for related resources"
  type        = string
  default     = "dmg-eks"
}

# ---- Networking ----
variable "vpc_name" {
  description = "Name tag of the VPC"
  type        = string
  default     = "dmg-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs of the two public subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs are required."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDRs of the two private subnets where the worker nodes run"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly two private subnet CIDRs are required."
  }
}

variable "security_group_ingress_cidr" {
  description = "Source CIDR allowed by the allow_tls security group (22, 80, 443, 3000)"
  type        = string
  default     = "0.0.0.0/0"
}

# ---- EKS cluster ----
variable "cluster_version" {
  description = "Kubernetes version for EKS (null = latest version EKS offers)"
  type        = string
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint (restrict to your IPs for better security)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_admin_arns" {
  description = "IAM user or role ARNs granted EKS cluster administrator access"
  type        = list(string)
  default     = [
    "arn:aws:iam::716403253120:user/terraform_user"
  ]
}

# ---- Worker nodes ----
variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t2.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT"
  type        = string
  default     = "SPOT"
}

variable "node_disk_size" {
  description = "Root disk size (GiB) of each worker node"
  type        = number
  default     = 20
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 12
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair (private key is written to <name>.pem)"
  type        = string
  default     = "moses-eks-key"
}

# ---- Helm chart versions ----
variable "cert_manager_chart_version" {
  description = "cert-manager Helm chart version"
  type        = string
  default     = "v1.21.2"
}

variable "nginx_ingress_chart_version" {
  description = "F5 NGINX Ingress Controller Helm chart version"
  type        = string
  default     = "2.7.2"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "10.10.1"
}

# ---- Ingress / TLS ----
variable "nginx_ingress_replicas" {
  description = "Number of NGINX ingress controller pods"
  type        = number
  default     = 1
}

variable "ingress_class_name" {
  description = "IngressClass created by the NGINX ingress controller"
  type        = string
  default     = "nginx"
}

variable "cluster_issuer_name" {
  description = "Name of the cert-manager ClusterIssuer (used in Ingress annotations)"
  type        = string
  default     = "letsencrypt-prod"
}

variable "letsencrypt_server" {
  description = "ACME server URL (production; use the staging URL for testing)"
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "letsencrypt_email" {
  description = "Optional contact email for the Let's Encrypt account"
  type        = string
  default     = "moses.daniel90@gmail.com"
}

# ---- Argo CD ----
variable "argocd_hostname" {
  description = "Public hostname for the Argo CD UI (must match manifests/argocd-ingress.yaml)"
  type        = string
  default     = "argocd.distechnologies.online"
}

# ---- EFS ----
variable "efs_transition_to_ia" {
  description = "When EFS moves unused files to Infrequent Access"
  type        = string
  default     = "AFTER_30_DAYS"
}

# ---- kubeconfig in S3 ----
variable "kubeconfig_bucket" {
  description = "S3 bucket where the admin kubeconfig is uploaded; set TF_VAR_kubeconfig_bucket in CI"
  type        = string
  default     = ""
}

variable "kubeconfig_s3_key" {
  description = "S3 object key of the admin kubeconfig"
  type        = string
  default     = "eks/kubeconfig"
}
