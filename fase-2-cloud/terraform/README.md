# Terraform

Esta pasta contem a infraestrutura declarativa da AWS para a Fase 2.

## O que ela cria

- VPC, subnets, IGW e NAT para a rede de workload do EKS
- cluster EKS e managed node group
- repositorios ECR para os 5 servicos
- 3 instancias PostgreSQL em RDS
- 1 replication group do Redis em ElastiCache
- 1 tabela DynamoDB
- 1 fila SQS
- add-ons principais do EKS

## Inicio rapido

```powershell
cd C:\Users\erisv\git\tech-challenge-fase2-togglemaster\fase-2-cloud\terraform
copy terraform.tfvars.example terraform.tfvars
copy backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Se voce precisar recriar a inicializacao do backend remoto, rode:

```powershell
terraform init -reconfigure -backend-config=backend.hcl
```

## Backend remoto

O backend S3 e a fonte oficial do state.

- `backend.hcl.example` mostra os parametros esperados.
- `use_lockfile = true` habilita lock no backend S3.
- `dynamodb_table` pode ser mantida para ambientes que ainda usem lock adicional.

## Modo de IAM

- `iam_mode = "personal"` mantem a criacao declarativa das roles do EKS.
- `iam_mode = "academy"` usa a role existente `LabRole` e nao cria roles ou policies novas.
- `academy_lab_role_name` permite ajustar o nome caso o ambiente Academy use um valor diferente.

## Outputs importantes

Use `terraform output` apos o `apply` para obter:

- nome e endpoint do cluster EKS
- URLs dos repositorios ECR
- endpoints do RDS
- endpoint do Redis
- URL da fila SQS
- valores base64 para os secrets do Kubernetes
- chaves brutas para validacao da API (`auth_service_master_key` e `service_api_key`)

## Observacoes

- O state nao deve ser tratado como local como fonte oficial.
- O endpoint publico do EKS esta habilitado para simplificar a validacao a partir de uma workstation.
- Se voce precisar de acesso mais restrito, reduza `cluster_public_access_cidrs` no `terraform.tfvars`.
