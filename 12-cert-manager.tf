# cert-manager: issues and renews TLS certificates (e.g. from Let's Encrypt)
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_chart_version
  namespace        = "cert-manager"
  create_namespace = true

  values = [yamlencode({
    crds = {
      enabled = true
    }
  })]

  depends_on = [aws_eks_node_group.node_group]
}

# Let's Encrypt ClusterIssuer, installed from the local chart in
# charts/cluster-issuer (a plain kubernetes_manifest would fail at plan time
# on a fresh cluster because the ClusterIssuer CRD doesn't exist yet)
resource "helm_release" "cluster_issuer" {
  name      = "cluster-issuer"
  chart     = "${path.module}/charts/cluster-issuer"
  namespace = helm_release.cert_manager.namespace

  values = [yamlencode(merge(
    {
      name             = var.cluster_issuer_name
      server           = var.letsencrypt_server
      ingressClassName = var.ingress_class_name
    },
    var.letsencrypt_email == "" ? {} : { email = var.letsencrypt_email },
  ))]

  # cert-manager's webhook must be running before the ClusterIssuer is created
  depends_on = [helm_release.cert_manager]
}
