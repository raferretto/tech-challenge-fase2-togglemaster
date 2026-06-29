# Terraform Provisioning Checklist

The cloud infrastructure for Phase 2 is now provisioned declaratively from `fase-2-cloud/terraform`.

Use this file as a high-level checklist of what Terraform creates and which outputs must be captured for the Kubernetes manifests.

## 1. EKS cluster

- Create the EKS cluster, VPC and managed node group with Terraform.
- Use the local Terraform state to keep the first delivery simple.
- Keep the node group in private subnets and expose the control plane publicly for workstation access.

## 2. Container registry

Create 5 ECR repositories:

- `auth-service`
- `flag-service`
- `targeting-service`
- `evaluation-service`
- `analytics-service`

- Push the container images built from the service directories.

## 3. PostgreSQL

Create 3 independent PostgreSQL databases:

- `auth-service` database
- `flag-service` database
- `targeting-service` database

- Recommended starting point:
  - small instance class for validation
  - private subnets
  - security group that allows traffic from the VPC CIDR

## 4. Redis

Create one ElastiCache for Redis cluster for the `evaluation-service`.

## 5. DynamoDB

Create a table named `ToggleMasterAnalytics`.

Suggested partition key:

- `event_id` as `String`

## 6. SQS

Create one Standard queue:

- `togglemaster-evaluation-events`

This queue is produced by `evaluation-service` and consumed by `analytics-service`.

## 7. Cluster add-ons

- Install Metrics Server after the Terraform apply
- Install the Nginx Ingress Controller after the Terraform apply

## 8. Final values to collect

Before applying the manifests, collect and store:

- RDS endpoints
- Redis endpoint
- SQS queue URL
- DynamoDB table name
- ECR image URLs
