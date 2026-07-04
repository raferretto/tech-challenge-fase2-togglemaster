data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# --- Metrics Server ---
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
  wait       = false

  depends_on = [aws_eks_node_group.this]
}

# --- NGINX Ingress Controller with IRSA ---
data "aws_iam_policy_document" "nginx_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:ingress-nginx:ingress-nginx-controller"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "nginx_ingress" {
  name               = "${var.project_name}-nginx-ingress"
  assume_role_policy = data.aws_iam_policy_document.nginx_assume_role.json
}

resource "aws_iam_role_policy_attachment" "nginx_ingress_elb" {
  role       = aws_iam_role.nginx_ingress.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.serviceAccount.name"
    value = "ingress-nginx-controller"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.nginx_ingress.arn
  }
  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "false"
  }

  wait             = false

  depends_on = [aws_eks_node_group.this, aws_iam_role.nginx_ingress]
}

# --- KEDA & SQS IRSA ---
data "aws_iam_policy_document" "keda_sqs_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:default:analytics-service-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "keda_sqs" {
  name               = "${var.project_name}-keda-sqs"
  assume_role_policy = data.aws_iam_policy_document.keda_sqs_assume_role.json
}

resource "aws_iam_role_policy" "keda_sqs_policy" {
  name = "${var.project_name}-keda-sqs-policy"
  role = aws_iam_role.keda_sqs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = aws_sqs_queue.events.arn
      }
    ]
  })
}

resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true

  wait             = false

  depends_on = [aws_eks_node_group.this]
}
