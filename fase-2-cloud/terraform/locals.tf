locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnet_cidrs  = [for index in range(2) : cidrsubnet(var.vpc_cidr, 4, index)]
  private_subnet_cidrs = [for index in range(2, 4) : cidrsubnet(var.vpc_cidr, 4, index)]

  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )

  cluster_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = merge(local.cluster_tags, {
    "kubernetes.io/role/elb" = "1"
  })

  private_subnet_tags = merge(local.cluster_tags, {
    "kubernetes.io/role/internal-elb" = "1"
  })

  ecr_repositories = toset([
    "auth-service",
    "flag-service",
    "targeting-service",
    "evaluation-service",
    "analytics-service",
  ])

  databases = {
    auth = {
      identifier = "${var.project_name}-auth-db"
      db_name    = "auth_db"
    }
    flags = {
      identifier = "${var.project_name}-flags-db"
      db_name    = "flags_db"
    }
    targeting = {
      identifier = "${var.project_name}-targeting-db"
      db_name    = "targeting_db"
    }
  }
}

