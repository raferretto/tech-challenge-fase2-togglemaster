## 1. Inventário e preparação

- [ ] 1.1 Inventariar comandos de build, testes, lint, SAST, SCA e Docker dos cinco serviços.
- [ ] 1.2 Definir variáveis, secrets, permissões, versões fixadas e convenção de tags por commit.
- [ ] 1.3 Definir os modos de execução AWS Academy e conta pessoal e documentar os dados necessários.

## 2. Infraestrutura como Código

- [ ] 2.1 Organizar o Terraform em componentes para VPC, subnets públicas e privadas, Internet Gateway e tabelas de rotas.
- [ ] 2.2 Provisionar cluster EKS e node groups usando `LabRole` no modo Academy e roles declarativas no modo pessoal.
- [ ] 2.3 Provisionar três instâncias RDS PostgreSQL para os serviços que possuem banco.
- [ ] 2.4 Provisionar cluster ElastiCache Redis, tabela DynamoDB `ToggleMasterAnalytics` e fila SQS.
- [ ] 2.5 Provisionar ou validar os cinco repositórios ECR.
- [ ] 2.6 Configurar backend remoto S3 para o `terraform.tfstate` e locking compatível.
- [ ] 2.7 Executar `terraform fmt`, `validate` e `plan`, documentando os recursos previstos.
- [ ] 2.8 Executar ou validar `terraform apply` e registrar evidências para a demonstração.

## 3. CI e DevSecOps dos cinco serviços

- [ ] 3.1 Criar workflows para `auth-service`, `flag-service`, `targeting-service`, `evaluation-service` e `analytics-service`.
- [ ] 3.2 Configurar execução em Pull Requests e pushes na branch principal.
- [ ] 3.3 Implementar build e testes unitários quando disponíveis para Go e Python.
- [ ] 3.4 Implementar lint e análise estática apropriados a cada linguagem.
- [ ] 3.5 Implementar SAST e SCA para código-fonte e dependências.
- [ ] 3.6 Configurar falha obrigatória para vulnerabilidades críticas.
- [ ] 3.7 Construir imagens Docker e executar container scan antes do push.
- [ ] 3.8 Autenticar no ECR de forma segura e publicar imagens com tag do commit.
- [ ] 3.9 Demonstrar uma falha provocada por vulnerabilidade e uma execução aprovada após correção.

## 4. GitOps e ArgoCD

- [ ] 4.1 Criar diretório ou repositório GitOps contendo os manifestos ou Helm Charts dos cinco serviços.
- [ ] 4.2 Remover a identidade de deploy baseada apenas em `latest` e usar referências por commit.
- [ ] 4.3 Adicionar etapa pós-publicação que atualize somente a imagem do serviço afetado no GitOps.
- [ ] 4.4 Validar os manifestos e documentar revisão e rollback pelo Git.
- [ ] 4.5 Instalar ArgoCD no EKS por Helm, Terraform ou mecanismo equivalente.
- [ ] 4.6 Configurar aplicações ArgoCD para monitorar e sincronizar os cinco serviços.
- [ ] 4.7 Verificar no ArgoCD a detecção, sincronização e saúde das aplicações.

## 5. Integração, documentação e entrega

- [ ] 5.1 Validar o fluxo completo: código, pipeline, ECR, atualização GitOps e ArgoCD.
- [ ] 5.2 Confirmar que falhas de qualidade ou segurança não alteram ECR nem GitOps.
- [ ] 5.3 Atualizar documentação de IaC, CI/CD, GitOps, ArgoCD, rollback e operação.
- [ ] 5.4 Preparar vídeo de até 20 minutos com plan/apply, segurança, GitOps e ArgoCD.
- [ ] 5.5 Preparar relatório com participantes, links, decisões, desafios e estimativa de custos AWS.
- [ ] 5.6 Validar o checklist final dos entregáveis da Fase 3.
