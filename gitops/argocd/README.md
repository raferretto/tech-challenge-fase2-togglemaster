# ArgoCD

Os arquivos nesta pasta descrevem a aplicacao ArgoCD que aponta para o overlay GitOps do ToggleMaster.

## Aplicacao

- `togglemaster-application.yaml` referencia o overlay `gitops/togglemaster`.
- O sync e automatizado com `prune` e `selfHeal`.

## Uso

1. Instale o ArgoCD via Terraform em `fase-2-cloud/terraform/argocd.tf`.
2. Aplique a aplicacao abaixo no cluster.
3. Ajuste `repoURL` para o repositorio Git real da submissao.
