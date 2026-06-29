# ToggleMaster - Fase 2 Cloud

Este repositório reúne a evolução da Fase 1 para a Fase 2.

- `tech-challenge-fase1-togglemaster/` fica como evidência histórica da Fase 1.
- `fase-2-local/` contém a validação local com `docker compose`.
- `fase-2-cloud/terraform/` contém a infraestrutura declarativa da AWS com Terraform.
- `fase-2-cloud/k8s/` contém os manifests Kubernetes dos 5 serviços.

## Como usar este guia

Siga as etapas nesta ordem:

1. Instale as ferramentas necessárias no Windows.
2. Configure o `aws configure`.
3. Crie a infraestrutura com Terraform.
4. Capture os outputs do Terraform.
5. Conecte seu terminal ao cluster EKS.
6. Instale os complementos do cluster.
7. Publique as imagens no ECR.
8. Gere os manifests prontos para deploy.
9. Aplique os manifests no Kubernetes.
10. Valide os endpoints e o fluxo fim a fim.

> Nota: este fluxo é o recomendado para uma conta AWS pessoal. Se você estiver usando AWS Academy, o PDF continua valendo como referência para limitações de permissões e uso da `LabRole`.

## 1. Instale as ferramentas no Windows

### 1.1 Docker Desktop

Instale o Docker Desktop e confirme:

```powershell
docker --version
docker compose version
```

### 1.2 AWS CLI v2

Instale o AWS CLI v2 a partir do MSI oficial:

```powershell
$msi = "$env:TEMP\AWSCLIV2.msi"
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $msi
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msi`" /qn"
aws --version
```

### 1.3 Terraform

Opção recomendada com `winget`:

```powershell
winget install -e --id Hashicorp.Terraform
terraform -version
```

Fallback manual, se preferir ZIP:

```powershell
$terraformVersion = "1.14.4"
$terraformZip = "$env:TEMP\terraform.zip"
New-Item -ItemType Directory -Force "$HOME\bin" | Out-Null
Invoke-WebRequest -Uri "https://releases.hashicorp.com/terraform/$terraformVersion/terraform_${terraformVersion}_windows_amd64.zip" -OutFile $terraformZip
Expand-Archive -Path $terraformZip -DestinationPath "$HOME\bin" -Force
$env:PATH = "$HOME\bin;$env:PATH"
terraform -version
```

### 1.4 kubectl

```powershell
$bin = Join-Path $HOME "bin"
New-Item -ItemType Directory -Force $bin | Out-Null
$kubectlVersion = Invoke-RestMethod -Uri "https://dl.k8s.io/release/stable.txt"
Invoke-WebRequest -Uri "https://dl.k8s.io/release/$kubectlVersion/bin/windows/amd64/kubectl.exe" -OutFile (Join-Path $bin "kubectl.exe")
$env:PATH = "$bin;$env:PATH"
kubectl version --client
```

### 1.5 Helm

```powershell
winget install -e --id Helm.Helm
helm version
```

> Observação: se o PowerShell reclamar de aspas em comandos do Terraform, rode apenas a etapa de `terraform init/plan/apply` no `cmd.exe`. O restante pode continuar no PowerShell.

## 2. Configure o AWS CLI

```powershell
aws configure
```

Informe:

- AWS Access Key ID
- AWS Secret Access Key
- Default region name: `us-east-1`
- Default output format: `json`

Valide a identidade:

```powershell
aws sts get-caller-identity
```

## 3. Prepare o Terraform

```powershell
cd C:\Users\erisv\git\toggle-master\fase-2-cloud\terraform
copy terraform.tfvars.example terraform.tfvars
```

Se quiser ajustar o ambiente, edite `terraform.tfvars`. Os principais parâmetros são:

- `aws_region`
- `cluster_name`
- `vpc_cidr`
- `cluster_public_access_cidrs`
- tamanhos dos nodes e instâncias

Para manter o restante do fluxo alinhado com o Terraform, defina estas variáveis na sessão:

```powershell
$env:AWS_REGION = "us-east-1"
$env:CLUSTER_NAME = "togglemaster-phase2"
$env:ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
$env:ECR_REPO_PREFIX = "$($env:ACCOUNT_ID).dkr.ecr.$($env:AWS_REGION).amazonaws.com"
```

## 4. Provisione a AWS com Terraform

```powershell
terraform init
terraform plan
terraform apply
```

O Terraform cria:

- VPC, subnets, IGW e NAT
- EKS com managed node group
- 5 repositórios ECR
- 3 bancos PostgreSQL em RDS
- 1 Redis em ElastiCache
- 1 tabela DynamoDB
- 1 fila SQS
- complementos principais do EKS

## 5. Capture os resultados do Terraform

```powershell
terraform output
terraform output -json > terraform-outputs.json
```

Use principalmente estes outputs:

- `ecr_repository_urls`
- `rds_endpoints`
- `redis_endpoint`
- `sqs_queue_url`
- `auth_service_database_url_b64`
- `flag_service_database_url_b64`
- `targeting_service_database_url_b64`
- `evaluation_service_redis_url_b64`
- `evaluation_service_sqs_url_b64`
- `analytics_service_sqs_url_b64`
- `auth_service_master_key_b64`
- `auth_service_master_key`
- `service_api_key_b64`
- `service_api_key`

Esses valores alimentam o script `fase-2-cloud/scripts/render-manifests.ps1`, que gera `fase-2-cloud/generated-k8s/`.

## 6. Conecte o terminal ao cluster

```powershell
aws eks update-kubeconfig --name $env:CLUSTER_NAME --region $env:AWS_REGION
kubectl get nodes
```

Se você alterou o `cluster_name` ou a região em `terraform.tfvars`, ajuste também as variáveis da sessão acima.

## 7. Instale os complementos do cluster

### 7.1 Metrics Server

```powershell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
```

### 7.2 Nginx Ingress Controller

```powershell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
kubectl get pods -n ingress-nginx
```

Volte para a raiz do repositório antes das etapas de compilação/envio e de aplicação dos manifests:

```powershell
cd C:\Users\erisv\git\toggle-master
```

## 8. Publique as imagens no ECR

Faça login no registro:

```powershell
aws ecr get-login-password --region $env:AWS_REGION | docker login --username AWS --password-stdin "$env:ECR_REPO_PREFIX"
```

Compile e envie as 5 imagens:

```powershell
$services = @("auth-service","flag-service","targeting-service","evaluation-service","analytics-service")
foreach ($svc in $services) {
  docker build -t "$env:ECR_REPO_PREFIX/$svc:latest" ".\$svc"
  docker push "$env:ECR_REPO_PREFIX/$svc:latest"
}
```

## 9. Gere os manifests prontos para deploy

Em vez de editar os manifests manualmente, renderize uma cópia dos arquivos com os outputs do Terraform:

```powershell
.\fase-2-cloud\scripts\render-manifests.ps1
```

O script:

- lê `terraform output -json`
- substitui as URIs de ECR em cada deployment
- preenche os secrets base64 em `secrets.yaml`
- escreve os manifests prontos em `fase-2-cloud/generated-k8s/`

Para testar as APIs protegidas, use os outputs crus `auth_service_master_key` e `service_api_key`.

## 10. Aplique os manifests Kubernetes

```powershell
kubectl apply -k .\fase-2-cloud\generated-k8s
kubectl get pods -n togglemaster
kubectl get svc -n togglemaster
kubectl get ingress -n togglemaster
kubectl get hpa -n togglemaster
```

## 11. Valide o ambiente

### 11.1 Descubra o endereço do Ingress

```powershell
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

Anote o `EXTERNAL-IP` ou `ADDRESS` retornado e substitua `<INGRESS_HOST>` nos exemplos abaixo.

### 11.2 Health checks

```powershell
Invoke-RestMethod -Uri "http://<INGRESS_HOST>/auth/health"
Invoke-RestMethod -Uri "http://<INGRESS_HOST>/flags/health"
Invoke-RestMethod -Uri "http://<INGRESS_HOST>/targeting/health"
Invoke-RestMethod -Uri "http://<INGRESS_HOST>/evaluate/health"
```

### 11.3 Validação de chave

```powershell
$serviceApiKey = terraform -chdir=.\fase-2-cloud\terraform output -raw service_api_key
$headers = @{ Authorization = "Bearer $serviceApiKey" }
Invoke-RestMethod -Uri "http://<INGRESS_HOST>/auth/validate" -Headers $headers
```

### 11.4 Fluxo de negócio

```powershell
$serviceApiKey = terraform -chdir=.\fase-2-cloud\terraform output -raw service_api_key
$headers = @{ Authorization = "Bearer $serviceApiKey" }

$flagBody = '{"name":"enable-new-dashboard","description":"Ativa o novo dashboard","is_enabled":true}'
Invoke-RestMethod -Uri "http://<INGRESS_HOST>/flags/flags" -Method Post -Headers $headers -ContentType "application/json" -Body $flagBody

$ruleBody = '{"flag_name":"enable-new-dashboard","is_enabled":true,"rules":{"type":"PERCENTAGE","value":50}}'
Invoke-RestMethod -Uri "http://<INGRESS_HOST>/targeting/rules" -Method Post -Headers $headers -ContentType "application/json" -Body $ruleBody

Invoke-RestMethod -Uri "http://<INGRESS_HOST>/evaluate/evaluate?user_id=user-123&flag_name=enable-new-dashboard"
Invoke-RestMethod -Uri "http://<INGRESS_HOST>/evaluate/evaluate?user_id=user-123&flag_name=enable-new-dashboard"
```

### 11.5 Escalabilidade e dados

```powershell
kubectl get hpa -n togglemaster -w
aws dynamodb scan --table-name ToggleMasterAnalytics --region us-east-1
```

## 12. Referências úteis

- Validação local: [`fase-2-local/README.md`](./fase-2-local/README.md)
- Artefatos cloud: [`fase-2-cloud/README.md`](./fase-2-cloud/README.md)
- Terraform: [`fase-2-cloud/terraform/README.md`](./fase-2-cloud/terraform/README.md)
- Manifests Kubernetes: [`fase-2-cloud/k8s`](./fase-2-cloud/k8s)
