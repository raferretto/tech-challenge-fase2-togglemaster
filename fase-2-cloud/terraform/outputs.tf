output "aws_region" {
  value = var.aws_region
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "eks_cluster_name" {
  value = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "eks_cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "ecr_repository_urls" {
  value = { for name, repo in aws_ecr_repository.service : name => repo.repository_url }
}

output "rds_endpoints" {
  value = {
    auth      = aws_db_instance.this["auth"].address
    flags     = aws_db_instance.this["flags"].address
    targeting = aws_db_instance.this["targeting"].address
  }
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.analytics.name
}

output "sqs_queue_name" {
  value = aws_sqs_queue.events.name
}

output "sqs_queue_url" {
  value = aws_sqs_queue.events.url
}

output "auth_service_database_url_b64" {
  value     = base64encode("postgres://${var.rds_master_username}:${random_password.rds_master.result}@${aws_db_instance.this["auth"].address}:5432/auth_db?sslmode=disable")
  sensitive = true
}

output "flag_service_database_url_b64" {
  value     = base64encode("postgres://${var.rds_master_username}:${random_password.rds_master.result}@${aws_db_instance.this["flags"].address}:5432/flags_db?sslmode=disable")
  sensitive = true
}

output "targeting_service_database_url_b64" {
  value     = base64encode("postgres://${var.rds_master_username}:${random_password.rds_master.result}@${aws_db_instance.this["targeting"].address}:5432/targeting_db?sslmode=disable")
  sensitive = true
}

output "evaluation_service_redis_url_b64" {
  value     = base64encode("redis://${aws_elasticache_replication_group.this.primary_endpoint_address}:6379/0")
  sensitive = true
}

output "evaluation_service_sqs_url_b64" {
  value     = base64encode(aws_sqs_queue.events.url)
  sensitive = true
}

output "analytics_service_sqs_url_b64" {
  value     = base64encode(aws_sqs_queue.events.url)
  sensitive = true
}

output "auth_service_master_key_b64" {
  value     = base64encode(random_password.auth_master_key.result)
  sensitive = true
}

output "auth_service_master_key" {
  value     = random_password.auth_master_key.result
  sensitive = true
}

output "service_api_key_b64" {
  value     = base64encode(random_password.service_api_key.result)
  sensitive = true
}

output "service_api_key" {
  value     = random_password.service_api_key.result
  sensitive = true
}
