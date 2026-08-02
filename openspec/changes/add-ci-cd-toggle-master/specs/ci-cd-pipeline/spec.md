## Purpose

Definir um processo repetível e protegido por gates de segurança para entregar os cinco microsserviços do ToggleMaster, desde a alteração no código até a imagem de contêiner versionada.

## ADDED Requirements

### Requirement: Validar os cinco serviços em eventos de código
O processo de entrega DEVE (MUST) possuir workflows para `auth-service`, `flag-service`, `targeting-service`, `evaluation-service` e `analytics-service`, executados em Pull Requests e em pushes na branch principal.

#### Scenario: Pull Request altera um serviço
- **QUANDO** um Pull Request alterar o código, dependências, Dockerfile ou workflow de um serviço
- **ENTÃO** o workflow correspondente será executado e reportará sucesso ou falha antes do merge

#### Scenario: Alteração chega à branch principal
- **QUANDO** uma alteração for enviada para a branch principal
- **ENTÃO** o workflow de validação e release será executado para o serviço afetado

### Requirement: Executar build, testes e qualidade
Cada workflow DEVE (MUST) compilar ou preparar o serviço usando sua toolchain, executar testes unitários quando disponíveis e executar lint ou análise estática apropriada à linguagem.

#### Scenario: Verificações de qualidade aprovadas
- **QUANDO** build, testes, lint e análise estática atenderem aos limites configurados
- **ENTÃO** o workflow poderá prosseguir para os scans de segurança

#### Scenario: Verificação de qualidade falha
- **QUANDO** build, testes ou análise estática falhar
- **ENTÃO** o workflow falhará e não publicará imagem nem atualizará o GitOps

### Requirement: Aplicar segurança DevSecOps como gate
Cada workflow DEVE (MUST) executar SAST no código-fonte, SCA nas dependências e scan de vulnerabilidades na imagem Docker. A identificação de uma vulnerabilidade crítica DEVE fazer o workflow falhar e impedir a publicação.

#### Scenario: Vulnerabilidade crítica é encontrada
- **QUANDO** SAST, SCA ou scan de contêiner identificar uma vulnerabilidade crítica
- **ENTÃO** o workflow falhará antes da publicação ou promoção do artefato

#### Scenario: Segurança aprovada
- **QUANDO** os scans concluírem sem vulnerabilidade crítica
- **ENTÃO** o workflow poderá publicar a imagem versionada

### Requirement: Publicar imagens identificáveis pelo commit
O processo de entrega DEVE (MUST) construir a imagem Docker de cada serviço validado e publicá-la no repositório ECR correspondente usando uma tag que identifique o commit de origem.

#### Scenario: Publicação bem-sucedida
- **QUANDO** todas as validações e scans forem aprovados em uma execução autorizada de release
- **ENTÃO** a imagem será enviada ao ECR com tag baseada no commit

#### Scenario: Imagem reprovada
- **QUANDO** o scan da imagem contiver uma vulnerabilidade crítica
- **ENTÃO** a imagem não será publicada como artefato liberável

### Requirement: Produzir evidências do pipeline
O processo DEVE (MUST) permitir demonstrar uma execução que falha por vulnerabilidade e uma execução posterior aprovada após a correção.

#### Scenario: Demonstração de falha e correção
- **QUANDO** uma dependência vulnerável ou falha de segurança for introduzida e depois corrigida
- **ENTÃO** os registros do pipeline deverão mostrar primeiro a falha no gate e depois a execução aprovada
