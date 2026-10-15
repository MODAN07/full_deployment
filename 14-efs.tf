# =============================================================================
# Amazon EFS + EFS CSI driver + Kubernetes StorageClass
# =============================================================================

# ---- EFS file system ----
resource "aws_efs_file_system" "efs" {
  creation_token   = "${var.cluster_name}-efs"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"

  # Move files not accessed for 30 days to the cheaper Infrequent Access class
  lifecycle_policy {
    transition_to_ia = var.efs_transition_to_ia
  }

  tags = {
    Name = "${var.cluster_name}-efs"
  }
}

# ---- Security group: allow NFS (2049) from inside the VPC ----
resource "aws_security_group" "efs" {
  name        = "${var.cluster_name}-efs-sg"
  description = "Allow NFS traffic to EFS from within the VPC"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "${var.cluster_name}-efs-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_nfs" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  from_port         = 2049
  ip_protocol       = "tcp"
  to_port           = 2049
}

resource "aws_vpc_security_group_egress_rule" "efs_all" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---- Mount targets: one per private subnet (where the worker nodes run) ----
resource "aws_efs_mount_target" "efs" {
  for_each = {
    private_01 = aws_subnet.private_subnet_01.id
    private_02 = aws_subnet.private_subnet_02.id
  }

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

# ---- EKS Pod Identity agent (lets add-ons get IAM roles without OIDC/IRSA) ----
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.node_group]
}

# ---- IAM role for the EFS CSI controller ----
resource "aws_iam_role" "efs_csi" {
  name = "${var.cluster_name}-efs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
  role       = aws_iam_role.efs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

# ---- EFS CSI driver as a managed EKS add-on ----
resource "aws_eks_addon" "efs_csi" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "aws-efs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  pod_identity_association {
    role_arn        = aws_iam_role.efs_csi.arn
    service_account = "efs-csi-controller-sa"
  }

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.efs_csi,
    aws_efs_mount_target.efs,
  ]
}

# ---- StorageClass: dynamic provisioning via EFS access points ----
resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs-sc"
    # Uncomment to make EFS the cluster's default StorageClass
    # annotations = {
    #   "storageclass.kubernetes.io/is-default-class" = "true"
    # }
  }

  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "Immediate"

  parameters = {
    provisioningMode = "efs-ap" # one EFS access point per PVC
    fileSystemId     = aws_efs_file_system.efs.id
    directoryPerms   = "700"
    basePath         = "/dynamic_provisioning"
  }

  depends_on = [aws_eks_addon.efs_csi]
}

