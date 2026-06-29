# Terraform

Esta pasta contém a infraestrutura declarativa da AWS para a Fase 2.

## O que ela cria

- VPC, subnets, IGW e NAT para a rede de workload do EKS
- cluster EKS e managed node group
- repositórios ECR para os 5 serviços
- 3 instâncias PostgreSQL em RDS
- 1 replication group do Redis em ElastiCache
- 1 tabela DynamoDB
- 1 fila SQS
- add-ons principais do EKS

## Início rápido

```powershell
cd C:\Users\erisv\git\toggle-master\fase-2-cloud\terraform
copy terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Outputs importantes

Use `terraform output` após o `apply` para obter:

- nome e endpoint do cluster EKS
- URLs dos repositórios ECR
- endpoints do RDS
- endpoint do Redis
- URL da fila SQS
- valores base64 para os secrets do Kubernetes
- chaves brutas para validação da API (`auth_service_master_key` e `service_api_key`)

## Observações

- O state é local por padrão.
- O endpoint público do EKS está habilitado para simplificar a validação a partir de uma workstation.
- Se você precisar de acesso mais restrito, reduza `cluster_public_access_cidrs` no `terraform.tfvars`.
