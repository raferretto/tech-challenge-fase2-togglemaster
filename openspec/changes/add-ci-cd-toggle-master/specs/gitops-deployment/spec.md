## Purpose

Definir a infraestrutura declarativa e o deploy dos serviços ToggleMaster por meio de Terraform, GitOps e sincronização automática do ArgoCD com o cluster EKS.

## ADDED Requirements

### Requirement: Provisionar a infraestrutura da Fase 3 com Terraform
O projeto DEVE (MUST) provisionar por Terraform a VPC, subnets públicas e privadas, Internet Gateway, tabelas de rotas, cluster EKS, node groups, três instâncias RDS PostgreSQL, um cluster ElastiCache Redis, a tabela DynamoDB `ToggleMasterAnalytics`, uma fila SQS e cinco repositórios ECR.

#### Scenario: Ambiente cloud é criado por código
- **QUANDO** `terraform plan` e `terraform apply` forem executados com as variáveis necessárias
- **ENTÃO** os recursos obrigatórios da Fase 3 serão descritos e criados sem depender de configuração manual no console

#### Scenario: Plano evidencia a infraestrutura
- **QUANDO** o `terraform plan` for executado
- **ENTÃO** o plano deverá permitir identificar os componentes de networking, computação, dados, mensageria e registry previstos

### Requirement: Manter o estado Terraform em backend remoto
O estado do Terraform DEVE (MUST) ser armazenado em um backend remoto S3 e não pode depender de um `terraform.tfstate` local como fonte oficial. O mecanismo de lock configurado deverá ser compatível com o ambiente escolhido.

#### Scenario: Inicialização do backend remoto
- **QUANDO** o Terraform for inicializado em uma máquina nova
- **ENTÃO** o estado oficial será recuperado do backend S3 compartilhado

#### Scenario: Estado local não é fonte oficial
- **QUANDO** dois operadores executarem o fluxo Terraform em momentos diferentes
- **ENTÃO** ambos utilizarão o mesmo estado remoto e não sobrescreverão a infraestrutura por estados locais divergentes

### Requirement: Suportar os modelos de IAM exigidos
A infraestrutura DEVE (MUST) suportar o uso da `LabRole` existente na AWS Academy sem criar roles ou policies proibidas, e DEVE permitir roles e policies gerenciadas pelo Terraform em contas pessoais quando esse modo for selecionado.

#### Scenario: Execução na AWS Academy
- **QUANDO** o modo Academy estiver configurado
- **ENTÃO** EKS e node groups utilizarão a `LabRole` informada por data source ou variável, sem criação de roles ou policies incompatíveis

#### Scenario: Execução em conta pessoal
- **QUANDO** o modo de conta pessoal estiver configurado
- **ENTÃO** as roles e policies necessárias poderão ser provisionadas de forma declarativa pelo Terraform

### Requirement: Manter o estado de deploy no Git
O estado de deploy dos cinco serviços DEVE (MUST) ser representado por manifestos Kubernetes ou Helm Charts versionados em uma área GitOps separada das preocupações do código da aplicação.

#### Scenario: Configuração de deploy revisada
- **QUANDO** a configuração de deploy for alterada
- **ENTÃO** a alteração será visível como diff versionado no Git, podendo ser revisada e revertida

### Requirement: Atualizar o GitOps após publicação
O processo de release DEVE (MUST) atualizar a referência da imagem no GitOps somente depois que a imagem passar pelas validações obrigatórias e for publicada com sucesso no ECR.

#### Scenario: Release validado atualiza o GitOps
- **QUANDO** a publicação da imagem de um serviço for concluída com sucesso
- **ENTÃO** a referência GitOps associada será atualizada para a tag daquele commit

#### Scenario: Release falho mantém o estado
- **QUANDO** a validação ou publicação falhar
- **ENTÃO** nenhuma nova referência de imagem será commitada no GitOps

### Requirement: Sincronizar os cinco serviços pelo ArgoCD
O ArgoCD DEVE (MUST) ser instalado no EKS, monitorar o estado GitOps e sincronizar os cinco microsserviços no namespace do ToggleMaster conforme a política configurada.

#### Scenario: ArgoCD detecta alteração
- **QUANDO** o ArgoCD observar uma alteração GitOps válida e commitada
- **ENTÃO** aplicará o estado desejado ao serviço correspondente no cluster

#### Scenario: Cluster converge para o Git
- **QUANDO** a sincronização terminar com sucesso
- **ENTÃO** os cinco serviços deverão refletir as versões declaradas no GitOps e o ArgoCD reportará as aplicações como sincronizadas e saudáveis

### Requirement: Entregar evidências e relatório da Fase 3
O projeto DEVE (MUST) produzir evidências do `terraform plan/apply`, do pipeline DevSecOps, da atualização do GitOps e da sincronização do ArgoCD, além de relatório com participantes, links de documentação e vídeo, decisões, desafios e estimativa de custos AWS.

#### Scenario: Vídeo de demonstração
- **QUANDO** a entrega for apresentada
- **ENTÃO** o vídeo de até 20 minutos deverá demonstrar IaC, falha e correção de segurança, atualização GitOps e sincronização ArgoCD

#### Scenario: Relatório de entrega
- **QUANDO** o relatório for submetido
- **ENTÃO** deverá conter participantes, links, resumo técnico, decisões e estimativa de custos
