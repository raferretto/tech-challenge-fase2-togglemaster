# Fase 2 Cloud

Esta pasta reúne a entrega cloud-ready da Fase 2 do ToggleMaster.

O que já está coberto:

- a validação local está em `fase-2-local/`
- o repositório histórico da Fase 1 continua intocado em `tech-challenge-fase1-togglemaster/`
- os artefatos cloud dos novos microsserviços ficam aqui
- a infraestrutura AWS é provisionada declarativamente com Terraform em `terraform/`

## O que está incluído

- manifests Kubernetes para os 5 serviços
- recursos de Namespace, ConfigMap, Secret, Ingress e HPA
- provisionamento Terraform para EKS, ECR, RDS, ElastiCache, DynamoDB e SQS
- runbooks de deploy e validação

## Estrutura de pastas

- `k8s/` - manifests Kubernetes prontos para adaptação à sua conta AWS
- `scripts/render-manifests.ps1` - renderiza `k8s/` em `generated-k8s/` usando os outputs do Terraform
- `docs/` - notas de arquitetura, provisionamento e validação
- `terraform/` - infraestrutura AWS declarativa e outputs
- `docs/deployment-runbook.md` - fluxo de build, push, apply e verificação

## Como usar esta entrega

1. Provisione os recursos cloud com o `terraform` dentro de `terraform/`.
2. Faça build e push das 5 imagens de serviço para o ECR.
3. Renderize os manifests com `scripts/render-manifests.ps1` para gerar `generated-k8s/`.
4. Aplique os manifests com `kubectl apply -k ./generated-k8s`.
5. Instale o Metrics Server e o Nginx Ingress Controller no cluster.
6. Valide as rotas do Ingress, o comportamento do HPA e o fluxo de analytics.

## Observações importantes

- Os manifests são intencionalmente genéricos para funcionar tanto em AWS Academy quanto em uma conta AWS pessoal.
- No AWS Academy, prefira o caminho com `LabRole` descrito no PDF.
- Em uma conta pessoal, você pode usar o fluxo padrão de EKS + IRSA.
- `analytics-service` é tratado como worker interno; ele não precisa ser exposto publicamente via Ingress.

## Estado atual

- A validação local com `docker compose` já está funcionando.
- Esta pasta é o próximo passo para a submissão completa da Fase 2.
- Nenhuma alteração foi feita no repositório da Fase 1.
