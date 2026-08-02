## Contexto

O repositório contém cinco serviços independentes em contêineres, Terraform parcial para AWS, manifestos Kubernetes e scripts de deploy. O desafio da Fase 3 exige completar a automação de infraestrutura e do ciclo de vida sem alterar a lógica de negócio. O desenho precisa atender às restrições de IAM da AWS Academy e também ao modelo de conta pessoal.

## Objetivos / Não objetivos

**Objetivos:**

- Cobrir com IaC todos os recursos obrigatórios do PDF e manter o estado em S3.
- Criar validação CI reproduzível para os cinco serviços Go e Python.
- Aplicar gates SAST, SCA e container scan com bloqueio crítico.
- Publicar imagens por commit no ECR e promover somente por GitOps.
- Instalar ArgoCD no EKS e demonstrar convergência do cluster ao Git.
- Produzir evidências e documentação necessárias para a avaliação.

**Não objetivos:**

- Refatorar lógica de flags, autenticação ou avaliação.
- Criar novos microsserviços ou alterar contratos de API.
- Adicionar service mesh ou plataforma de observabilidade não exigida pelo desafio.
- Fazer deploy de produção diretamente pelo CI com `kubectl`.

## Decisões

### Terraform componentizado e backend remoto

O Terraform será organizado por responsabilidades, mantendo networking, EKS, dados, mensageria, registry e permissões identificáveis. O backend S3 será a fonte oficial do estado, com locking compatível com a versão do Terraform. A opção de backend local foi rejeitada porque viola o requisito de estado remoto.

### Dois modos de IAM

Variáveis ou data sources separarão o modo AWS Academy do modo conta pessoal. No Academy, a `LabRole` será referenciada sem criar roles ou policies. Na conta pessoal, roles e policies poderão ser criadas pelo Terraform. Essa separação evita que a solução dependa de permissões indisponíveis no Academy.

### Workflows por serviço com contrato comum

Cada um dos cinco serviços terá workflow acionado por Pull Request e branch principal. As etapas comuns serão build, testes, lint, SAST, SCA, build da imagem, scan de contêiner e, somente na branch principal após aprovação, publicação no ECR. Os comandos serão específicos para Go ou Python.

### Bloqueio por vulnerabilidade crítica

SAST, SCA e scan de imagem usarão uma política explícita de severidade crítica. A falha ocorrerá antes do ECR e do GitOps. Isso atende à exigência de demonstrar tanto uma falha intencional quanto a correção posterior.

### GitOps com ArgoCD

Os manifestos existentes serão reorganizados em uma área GitOps com tags de imagem imutáveis ou identificáveis pelo commit. O CI atualizará somente a referência do serviço publicado. O ArgoCD será instalado no EKS e monitorará o estado GitOps. `kubectl apply` direto pelo pipeline foi rejeitado por contrariar o fluxo pedido.

### Evidências como critério de aceite

Além dos artefatos técnicos, serão coletados logs, telas e links para demonstrar `terraform plan/apply`, falha e sucesso do pipeline, alteração GitOps e sincronização ArgoCD. A documentação incluirá custos AWS, desafios e decisões.

## Riscos / Compensações

- [Restrições da AWS Academy] → Manter caminho explícito com `LabRole` e testar separadamente o modo de conta pessoal.
- [Estado remoto S3 indisponível ou mal configurado] → Validar backend em ambiente novo antes de aplicar recursos e documentar recuperação.
- [Diferenças entre Go e Python] → Usar contrato comum com etapas específicas e versões fixadas.
- [Scanners com falsos positivos] → Fixar versões, registrar política de exceções e nunca ignorar vulnerabilidades críticas sem decisão documentada.
- [Conflitos em atualizações GitOps] → Alterar somente o serviço afetado e usar commits serializados ou tratamento de conflitos.
- [Falha no ArgoCD ou manifests inválidos] → Validar manifests antes da sincronização e usar o commit anterior como rollback.
- [Custos AWS do ambiente] → Registrar estimativa antes do apply e destruir recursos temporários após a demonstração quando possível.
