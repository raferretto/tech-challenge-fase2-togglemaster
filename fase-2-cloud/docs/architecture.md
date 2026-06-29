# Phase 2 Architecture

## Summary

ToggleMaster evolved from the Phase 1 monolith into a microservices platform with 5 services:

- `auth-service`
- `flag-service`
- `targeting-service`
- `evaluation-service`
- `analytics-service`

The first four services expose HTTP APIs. The last one is a worker that consumes SQS events and persists analytics records to DynamoDB.

## Data flow

1. `auth-service` validates API keys and seeds the service key used by `evaluation-service`.
2. `flag-service` stores feature flag definitions in PostgreSQL.
3. `targeting-service` stores routing and segmentation rules in PostgreSQL.
4. `evaluation-service` reads flag and targeting data, caches hot-path decisions in Redis, and publishes events to SQS.
5. `analytics-service` consumes SQS messages and persists event records to DynamoDB.

## Cloud dependencies

- PostgreSQL for `auth-service`
- PostgreSQL for `flag-service`
- PostgreSQL for `targeting-service`
- Redis for `evaluation-service`
- SQS for event transport
- DynamoDB for analytics storage

## Kubernetes layout

- one namespace for the platform
- one deployment and one ClusterIP service per microservice
- ingress routes for the public APIs
- CPU-based HPA for `evaluation-service` and `analytics-service`

## Design goal

Keep the local behavior validated in `fase-2-local/` and make the cloud delivery a direct evolution of that behavior, not a rewrite.
