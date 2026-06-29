# Deployment Runbook

## Prerequisites

- Terraform applied successfully in `fase-2-cloud/terraform`
- `kubectl` configured to point to the cluster
- `aws` CLI configured for the target account
- Terraform outputs captured for secrets and image URLs

## 1. Build and push images

Build the 5 container images from the service folders and push them to the ECR repository URLs returned by `terraform output ecr_repository_urls`.

Example flow:

```powershell
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
docker build -t <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/auth-service:latest .\auth-service
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/auth-service:latest
```

Repeat the same pattern for:

- `flag-service`
- `targeting-service`
- `evaluation-service`
- `analytics-service`

## 2. Render the Kubernetes manifests

Run `fase-2-cloud/scripts/render-manifests.ps1` to create `fase-2-cloud/generated-k8s/` from the Terraform outputs.

The script:

- replaces the placeholder image references in `k8s/*.yaml`
- replaces the placeholder base64 values in `k8s/secrets.yaml`
- keeps the connection strings aligned with the RDS, Redis and SQS values emitted by Terraform

## 3. Apply the manifests

```powershell
kubectl apply -k .\generated-k8s
```

## 4. Check the rollout

```powershell
kubectl get pods -n togglemaster
kubectl get svc -n togglemaster
kubectl get ingress -n togglemaster
kubectl get hpa -n togglemaster
```

## 5. Validate the public endpoints

- `GET /auth/health`
- `GET /flags/health`
- `GET /targeting/health`
- `GET /evaluate/health`

## 6. Validate autoscaling

- generate load against `evaluation-service`
- confirm `kubectl get hpa` shows scaling activity
- send enough messages to SQS to increase `analytics-service` CPU usage
- confirm the worker scales and records items in DynamoDB

## 7. Collect evidence

- pod list
- ingress address
- HPA status
- SQS activity
- DynamoDB table records
