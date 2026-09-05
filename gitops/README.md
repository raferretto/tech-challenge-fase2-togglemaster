# GitOps

Esta pasta guarda a overlay GitOps da Fase 3.

## Estrutura

- `togglemaster/` contem o overlay autocontido dos cinco servicos com tag por commit.
- `argocd/` contem a Application que aponta para o overlay `togglemaster/`.

## Como atualizar a imagem de um servico

```powershell
.\scripts\update-gitops-image.ps1 -Service auth-service -Tag <git-sha>
```

## Validacao

```powershell
kubectl kustomize .\gitops\togglemaster
.\scripts\validate-gitops.ps1
```

O script valida a renderizacao do Kustomize sem precisar de cluster. Depois de
configurar o EKS, execute tambem `kubectl apply --dry-run=server -k
.\gitops\togglemaster` para validar os recursos contra a API Kubernetes.

## Rollback

- Use `git revert` no commit que alterou a tag do servico.
- Reaplique o overlay no ArgoCD para voltar ao estado anterior.
