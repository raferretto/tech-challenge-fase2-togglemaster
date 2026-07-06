resource "random_password" "rds_master" {
  length  = 24
  special = false
}

resource "random_password" "auth_master_key" {
  length  = 24
  special = false
}

resource "random_password" "service_api_key" {
  length  = 32
  special = false
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = { for index, cidr in local.public_subnet_cidrs : tostring(index) => cidr }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = local.azs[tonumber(each.key)]
  map_public_ip_on_launch = true

  tags = merge(local.tags, local.public_subnet_tags, {
    Name = "${var.project_name}-public-${each.key}"
  })
}

resource "aws_subnet" "private" {
  for_each = { for index, cidr in local.private_subnet_cidrs : tostring(index) => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = local.azs[tonumber(each.key)]

  tags = merge(local.tags, local.private_subnet_tags, {
    Name = "${var.project_name}-private-${each.key}"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.tags, {
    Name = "${var.project_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["0"].id

  depends_on = [aws_internet_gateway.this]

  tags = merge(local.tags, {
    Name = "${var.project_name}-nat"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.this.id
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-private-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
  ])

  role       = aws_iam_role.eks_cluster.name
  policy_arn = each.value
}

resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodes" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])

  role       = aws_iam_role.eks_nodes.name
  policy_arn = each.value
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = [for subnet in aws_subnet.private : subnet.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.cluster_public_access_cidrs
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]

  tags = merge(local.tags, {
    Name = var.cluster_name
  })
}

resource "aws_launch_template" "eks_ng" {
  name_prefix = "${var.cluster_name}-ng-"
  
  user_data = base64encode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"

--BOUNDARY
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  kubelet:
    config:
      maxPods: 11
--BOUNDARY--
EOF
  )
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-managed-ng"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [for subnet in aws_subnet.private : subnet.id]
  instance_types  = [var.node_instance_type]
  capacity_type   = "ON_DEMAND"
  ami_type        = "AL2023_x86_64_STANDARD"

  launch_template {
    id      = aws_launch_template.eks_ng.id
    version = aws_launch_template.eks_ng.latest_version
  }

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  depends_on = [aws_iam_role_policy_attachment.eks_nodes]

  tags = merge(local.tags, {
    Name = "${var.cluster_name}-managed-ng"
  })
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                 = aws_eks_cluster.this.name
  addon_name                   = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                 = aws_eks_cluster.this.name
  addon_name                   = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                 = aws_eks_cluster.this.name
  addon_name                   = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}

resource "aws_ecr_repository" "service" {
  for_each = local.ecr_repositories

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.tags, {
    Name = each.value
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow Kubernetes workloads to access PostgreSQL"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-rds-sg"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]

  tags = merge(local.tags, {
    Name = "${var.project_name}-db-subnets"
  })
}

resource "aws_db_instance" "this" {
  for_each = local.databases

  identifier             = each.value.identifier
  db_name                = each.value.db_name
  engine                 = "postgres"
  instance_class         = var.rds_instance_class
  allocated_storage      = 20
  storage_type           = "gp3"
  username               = var.rds_master_username
  password               = random_password.rds_master.result
  port                   = 5432
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
  apply_immediately      = true
  backup_retention_period = 0
  multi_az               = false
  auto_minor_version_upgrade = true
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]

  tags = merge(local.tags, {
    Name = each.value.identifier
  })
}

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Allow Kubernetes workloads to access Redis"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Redis from VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-redis-sg"
  })
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project_name}-cache-subnets"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id          = "${var.project_name}-redis"
  description                   = "ToggleMaster Redis"
  engine                        = "redis"
  node_type                     = var.redis_node_type
  port                          = 6379
  automatic_failover_enabled    = false
  multi_az_enabled              = false
  num_cache_clusters            = 1
  subnet_group_name             = aws_elasticache_subnet_group.this.name
  security_group_ids            = [aws_security_group.redis.id]
  at_rest_encryption_enabled    = false
  transit_encryption_enabled    = false
  apply_immediately             = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-redis"
  })
}

resource "aws_dynamodb_table" "analytics" {
  name         = "ToggleMasterAnalytics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  tags = merge(local.tags, {
    Name = "ToggleMasterAnalytics"
  })
}

resource "aws_sqs_queue" "events_dlq" {
  name = "togglemaster-evaluation-events-dlq"

  tags = merge(local.tags, {
    Name = "togglemaster-evaluation-events-dlq"
  })
}

resource "aws_sqs_queue" "events" {
  name = "togglemaster-evaluation-events"

  visibility_timeout_seconds = 60

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.events_dlq.arn
    maxReceiveCount     = 5
  })

  tags = merge(local.tags, {
    Name = "togglemaster-evaluation-events"
  })
}
