# Fase 2 Cloud

Esta pasta reune a entrega cloud-ready da Fase 2 do ToggleMaster.

O que ja esta coberto:

- a validacao local esta em `fase-2-local/`
- o repositorio historico da Fase 1 continua intocado em `tech-challenge-fase1-togglemaster/`
- os artefatos cloud dos novos microsservicos ficam aqui
- a infraestrutura AWS e provisionada declarativamente com Terraform em `terraform/`
- a instalacao do ArgoCD e feita por Terraform em `terraform/argocd.tf`
- o overlay GitOps autocontido fica em `../gitops/`

## O que esta incluido

- manifests Kubernetes para os 5 servicos
- recursos de Namespace, ConfigMap, Secret, Ingress e HPA
- provisionamento Terraform para EKS, ECR, RDS, ElastiCache, DynamoDB, SQS e ArgoCD
- runbooks de deploy, validacao, entrega e Fase 3

## Estrutura de pastas

- `k8s/` - manifests Kubernetes da fase anterior
- `gitops/` - overlay GitOps autocontido e Application do ArgoCD
- `scripts/render-manifests.ps1` - renderiza `k8s/` em `generated-k8s/` usando os outputs do Terraform
- `docs/` - notas de arquitetura, provisionamento, Fase 3, entrega e validacao
- `terraform/` - infraestrutura AWS declarativa e outputs

## Como usar esta entrega

1. Provisione os recursos cloud com o `terraform` dentro de `terraform/`.
2. Faca build e push das 5 imagens de servico para o ECR.
3. Atualize a tag do overlay GitOps para o commit desejado.
4. Aplique a Application do ArgoCD apontando para `gitops/togglemaster`.
5. Sincronize o ArgoCD e valide os cinco servicos.

## Observacoes importantes

- Os manifests sao intencionalmente genericos para funcionar tanto em AWS Academy quanto em uma conta AWS pessoal.
- No AWS Academy, prefira o caminho com `LabRole` descrito no PDF.
- Em uma conta pessoal, voce pode usar o fluxo padrao de EKS + IRSA.
- `analytics-service` e tratado como worker interno; ele nao precisa ser exposto publicamente via Ingress.

## Estado atual

- A validacao local com `docker compose` ja esta funcionando.
- A entrega da Fase 3 e implementada em artefatos separados.
- Nenhuma alteracao foi feita no repositorio da Fase 1.
