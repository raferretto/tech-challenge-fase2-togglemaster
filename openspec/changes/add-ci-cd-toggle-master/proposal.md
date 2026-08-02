## Why

O ToggleMaster possui cinco microsserviços e uma base de infraestrutura cloud, mas o ciclo de entrega ainda depende de operações manuais e não oferece uma barreira consistente contra vulnerabilidades. A Fase 3 exige transformar esse ambiente em uma plataforma reproduzível, segura e controlada por Git, cobrindo IaC, CI, DevSecOps, CD e GitOps.

## What Changes

- Estruturar o Terraform para provisionar networking, EKS, node groups, bancos, cache, mensageria e repositórios necessários.
- Configurar backend remoto S3 para o estado do Terraform, sem manter o `terraform.tfstate` apenas localmente.
- Suportar os modos de execução da AWS Academy, usando a `LabRole`, e de conta AWS pessoal, com roles gerenciadas por Terraform quando aplicável.
- Criar workflows para `auth-service`, `flag-service`, `targeting-service`, `evaluation-service` e `analytics-service`.
- Executar os workflows em Pull Requests e em pushes na branch principal.
- Executar build, testes unitários quando disponíveis, lint, análise estática, SAST, SCA e scan de imagens Docker.
- Bloquear a entrega quando qualquer etapa identificar vulnerabilidade crítica.
- Publicar imagens no ECR usando tags baseadas no commit.
- Organizar os manifestos Kubernetes ou Helm Charts em uma área GitOps versionada.
- Instalar e configurar ArgoCD para monitorar o GitOps e sincronizar os cinco microsserviços no EKS.
- Atualizar automaticamente a tag da imagem no GitOps somente após a validação e publicação bem-sucedidas.
- Preparar evidências de `terraform plan/apply`, falha e sucesso de segurança, atualização GitOps e sincronização ArgoCD para o vídeo e o relatório da Fase 3.

## Capabilities

### New Capabilities

- `ci-cd-pipeline`: Validação, análise de segurança, empacotamento e publicação versionada dos cinco microsserviços.
- `gitops-deployment`: Infraestrutura declarativa, atualização de manifestos e sincronização automática dos serviços por GitOps e ArgoCD.

### Modified Capabilities

Nenhuma capacidade existente em `openspec/specs/` foi encontrada para modificar.

## Impact

- Workflows de CI/CD, testes, linters, scanners e permissões de execução.
- Dockerfiles e processo de publicação no AWS ECR.
- Projeto Terraform, backend remoto S3, networking, EKS, RDS, ElastiCache, DynamoDB, SQS e IAM.
- Manifestos Kubernetes, configuração do ArgoCD e organização do material GitOps.
- Integração operacional entre GitHub, ECR, repositório GitOps, ArgoCD e EKS.
- Documentação, checklist de validação, evidências do vídeo e relatório com estimativa de custos.
- Os contratos funcionais das APIs dos microsserviços e o fluxo local com Docker Compose não serão alterados.
