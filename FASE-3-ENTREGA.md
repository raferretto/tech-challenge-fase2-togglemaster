# Fase 3 - Status da Entrega

## Objetivo

Automatizar o ciclo de entrega dos cinco microsservicos do ToggleMaster, desde
a validacao do codigo ate o deploy declarativo. A solucao combina Terraform,
CI/CD com gates de seguranca, imagens versionadas no ECR, GitOps e ArgoCD.

## O que foi entregue

### Infraestrutura como codigo

- Terraform para VPC, subnets, EKS, node group, RDS PostgreSQL, Redis,
  DynamoDB, SQS, ECR e ArgoCD.
- Configuracao prevista para AWS Academy (`LabRole`) e conta AWS pessoal.
- Backend remoto S3 documentado e arquivo de exemplo para suas configuracoes.

### CI/CD e seguranca

- Workflow do GitHub Actions para `auth-service`, `flag-service`,
  `targeting-service`, `evaluation-service` e `analytics-service`.
- Build, testes, lint, analise estatica, SAST, SCA e scan de imagens.
- Falha obrigatoria quando um scan encontra vulnerabilidade critica.
- Imagens identificadas pelo SHA do commit, sem promocao baseada em `latest`.
- Deteccao dos servicos alterados para evitar processar servicos sem mudanca.

### GitOps e ArgoCD

- Manifestos GitOps versionados em `gitops/` para os cinco servicos.
- Script que atualiza somente a tag da imagem do servico publicado.
- Atualizacao GitOps executada pelo pipeline somente depois de publicar a
  imagem no ECR.
- Configuracao do ArgoCD para monitorar e sincronizar o estado GitOps.

### Validacao local

- Ambiente Docker Compose com bancos, Redis, DynamoDB Local e ElasticMQ.
- Script `scripts/test-local.ps1` que valida health checks, autenticacao,
  flags, regras, avaliacao, cache, eventos de analytics e renderizacao GitOps.
- Bootstrap local compativel com containers Linux, com scripts shell em LF.

## Como validar localmente

Com o Docker Desktop em execucao, rode na raiz do repositorio:

```powershell
.\scripts\test-local.ps1
```

Para manter os containers ativos ao final:

```powershell
.\scripts\test-local.ps1 -KeepEnvironment
```

Para incluir as verificacoes estaticas do Terraform, sem acessar a AWS:

```powershell
.\scripts\test-local.ps1 -IncludeTerraform
```

## Pendencias para aceite completo

Estas etapas dependem de uma conta AWS, credenciais e acesso ao GitHub Actions:

- Configurar `backend.hcl`, `terraform.tfvars` e credenciais AWS.
- Executar e registrar `terraform plan` e `terraform apply`.
- Configurar os secrets do GitHub Actions para OIDC e ECR.
- Demonstrar um pipeline reprovado por vulnerabilidade critica e outro
  aprovado apos a correcao.
- Confirmar a imagem publicada no ECR e a alteracao automatica no GitOps.
- Substituir `REPLACE_ME_REPOSITORY_URL` em
  `gitops/argocd/togglemaster-application.yaml` pela URL do repositorio.
- Confirmar no ArgoCD que as aplicacoes estao `Synced` e `Healthy`.
- Registrar as evidencias do fluxo completo para video e relatorio.
