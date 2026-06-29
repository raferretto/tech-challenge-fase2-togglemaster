variable "aws_region" {
  description = "AWS region where all resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Logical environment name used for tagging."
  type        = string
  default     = "phase2"
}

variable "project_name" {
  description = "Project prefix used for resource names."
  type        = string
  default     = "togglemaster"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "togglemaster-phase2"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "cluster_public_access_cidrs" {
  description = "CIDR ranges allowed to reach the EKS public endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_type" {
  description = "Instance type used by the managed node group."
  type        = string
  default     = "t3.medium"
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "rds_instance_class" {
  description = "RDS instance class for the PostgreSQL databases."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_master_username" {
  description = "Master username shared by the PostgreSQL instances."
  type        = string
  default     = "toggle"
}

variable "redis_node_type" {
  description = "ElastiCache node type for Redis."
  type        = string
  default     = "cache.t3.micro"
}

variable "service_api_key_name" {
  description = "Name used by auth-service to seed the evaluation-service API key."
  type        = string
  default     = "evaluation-service-key"
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

