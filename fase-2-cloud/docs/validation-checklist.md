# Validation Checklist

## Local

- `docker compose -f .\fase-2-local\docker-compose.yml up -d --build`
- all 5 services are healthy
- `auth-service` validates the seeded key
- `flag-service` can create and list flags
- `targeting-service` can create and list rules
- `evaluation-service` returns a decision and hits Redis cache on repeat calls
- `analytics-service` consumes SQS messages and writes to DynamoDB Local

## Cloud

- `kubectl get pods` shows all 5 services running
- `kubectl get svc` shows ClusterIP services for all applications
- the Ingress routes `/auth`, `/flags`, `/targeting` and `/evaluate`
- `evaluation-service` scales when CPU increases
- `analytics-service` scales when event load increases
- DynamoDB receives records from the analytics worker

## Evidence to capture

- cluster and node group status
- pod list
- ingress address
- HPA status
- SQS queue activity
- DynamoDB table records
