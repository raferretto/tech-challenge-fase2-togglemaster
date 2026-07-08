# Fase 2 Local

Esta pasta contém a infraestrutura local para validar o challenge da Fase 2 com `docker compose`.

## O que sobe no ambiente

- `auth-service` em `http://localhost:8001`
- `flag-service` em `http://localhost:8002`
- `targeting-service` em `http://localhost:8003`
- `evaluation-service` em `http://localhost:8004`
- `analytics-service` em `http://localhost:8005`
- PostgreSQL do `auth-service` em `localhost:5432`
- PostgreSQL compartilhado para `flag-service` e `targeting-service` em `localhost:5433`
- Redis em `localhost:6379`
- DynamoDB Local em `localhost:8000`
- ElasticMQ em `localhost:9324`

## Como executar

1. Abra um terminal na raiz do repositório:

```powershell
cd C:\Users\erisv\git\toggle-master
```

2. Suba o ambiente local:

```powershell
docker compose -f .\fase-2-local\docker-compose.yml up -d --build
```

3. Verifique se os containers estão saudáveis:

```powershell
docker compose -f .\fase-2-local\docker-compose.yml ps
```

4. Se quiser acompanhar os logs:

```powershell
docker compose -f .\fase-2-local\docker-compose.yml logs -f
```

## Fluxo de validação

Ordem recomendada para testar o projeto:

1. Validar os endpoints de `health`.
2. Validar a chave de serviço no `auth-service`.
3. Criar uma feature flag no `flag-service`.
4. Criar uma regra de segmentação no `targeting-service`.
5. Chamar o `evaluation-service` duas vezes.
6. Conferir se o `analytics-service` consumiu a mensagem.
7. Conferir o item gravado no DynamoDB Local.

## Chave local do ambiente

O ambiente local já semeia uma chave de serviço fixa para o `evaluation-service`:

```text
tm_key_evaluation_local
```

Ela é usada nas chamadas protegidas do `flag-service`, `targeting-service` e na validação do `auth-service`.

## Endpoints por serviço

### auth-service

`GET /health`
- Verifica se o serviço está no ar.
- Resposta esperada: `{"status":"ok"}`

```powershell
Invoke-RestMethod -Uri http://localhost:8001/health
```

`GET /validate`
- Valida uma chave enviada no header `Authorization: Bearer <chave>`.
- No ambiente local, a chave válida é `tm_key_evaluation_local`.
- Resposta esperada quando válido: `{"message":"Chave válida"}`

```powershell
$headers = @{ Authorization = 'Bearer tm_key_evaluation_local' }
Invoke-RestMethod -Uri http://localhost:8001/validate -Headers $headers
```

`POST /admin/keys`
- Cria uma nova chave de API.
- Exige `Authorization: Bearer admin-secreto-123`.
- Corpo esperado:

```json
{
  "name": "nome-do-servico"
}
```

- Retorna uma chave nova em texto plano uma única vez.

```powershell
$headers = @{ Authorization = 'Bearer admin-secreto-123' }
$body = '{"name":"nome-do-servico"}'
Invoke-RestMethod -Uri http://localhost:8001/admin/keys -Method Post -Headers $headers -ContentType 'application/json' -Body $body
```

### flag-service

`GET /health`
- Health check do serviço.

```powershell
Invoke-RestMethod -Uri http://localhost:8002/health
```

`POST /flags`
- Cria uma feature flag.
- Exige `Authorization: Bearer <chave-valida>`.
- Corpo esperado:

```json
{
  "name": "enable-new-dashboard",
  "description": "Ativa o novo dashboard para usuarios",
  "is_enabled": true
}
```

```powershell
$headers = @{ Authorization = 'Bearer tm_key_evaluation_local' }
$body = '{"name":"enable-new-dashboard","description":"Ativa o novo dashboard para usuarios","is_enabled":true}'
Invoke-RestMethod -Uri http://localhost:8002/flags -Method Post -Headers $headers -ContentType 'application/json' -Body $body
```

`GET /flags`
- Lista todas as flags.
- Exige autenticação.

```powershell
$headers = @{ Authorization = 'Bearer tm_key_evaluation_local' }
Invoke-RestMethod -Uri http://localhost:8002/flags -Headers $headers
```

`GET /flags/{name}`
- Busca uma flag pelo nome.
- Exige autenticação.

```powershell
$headers = @{ Authorization = 'Bearer tm_key_evaluation_local' }
Invoke-RestMethod -Uri http://localhost:8002/flags/enable-new-dashboard -Headers $headers
```

`PUT /flags/{name}`
- Atualiza uma flag existente.
- Exige autenticação.
- Campos aceitos: `description`, `is_enabled`.

```powershell
$headers = @{ Authorization = 'Bearer tm_key_evaluation_local' }
$body = '{"description":"Nova descricao","is_enabled":false}'
Invoke-RestMethod -Uri http://localhost:8002/flags/enable-new-dashboard -Method Put -Headers $headers -ContentType 'application/json' -Body $body
```

`DELETE /flags/{name}`
- Remove uma flag.
- Exige autenticação.

```powershell
$headers = @{ Authorization = 'Bearer tm_key_evaluation_local' }
Invoke-RestMethod -Uri http://localhost:8002/flags/enable-new-dashboard -Method Delete -Headers $headers
```

### targeting-service

`GET /health`
- Health check do serviço.

```powershell
Invoke-RestMethod -Uri http://localhost:8003/health
```

`POST /rules`
- Cria uma regra de segmentação para uma flag.
- Exige autenticação.
- Corpo esperado:

```json
{
  "flag_name": "enable-new-dashboard",
  "is_enabled": true,
  "rules": {
    "type": "PERCENTAGE",
    "value": 50
  }
}
```

```powershell
$headers = @{ Authorization = 'Bearer tm_key_evaluation_local' }
$body = '{"flag_name":"enable-new-dashboard","is_enabled":true,"rules":{"type":"PERCENTAGE","value":50}}'
Invoke-RestMethod -Uri http://localhost:8003/rules -Method Post -Headers $headers -ContentType 'application/json' -Body $body
```

`GET /rules/{flag_name}`
- Busca a regra da flag informada.
- Exige autenticação.

```powershell
$headers = @{ Authorization = 'Bearer tm_key_evaluation_local' }
Invoke-RestMethod -Uri http://localhost:8003/rules/enable-new-dashboard -Headers $headers
```

`PUT /rules/{flag_name}`
- Atualiza a regra da flag informada.
- Exige autenticação.
- Campos aceitos: `rules`, `is_enabled`.

```powershell
$headers = @{ Authorization = 'Bearer tm_key_evaluation_local' }
$body = '{"rules":{"type":"PERCENTAGE","value":75},"is_enabled":true}'
Invoke-RestMethod -Uri http://localhost:8003/rules/enable-new-dashboard -Method Put -Headers $headers -ContentType 'application/json' -Body $body
```

`DELETE /rules/{flag_name}`
- Remove a regra da flag informada.
- Exige autenticação.

```powershell
$headers = @{ Authorization = 'Bearer tm_key_evaluation_local' }
Invoke-RestMethod -Uri http://localhost:8003/rules/enable-new-dashboard -Method Delete -Headers $headers
```

### evaluation-service

`GET /health`
- Health check do serviço.

```powershell
Invoke-RestMethod -Uri http://localhost:8004/health
```

`GET /evaluate?user_id=...&flag_name=...`
- Calcula a decisão final da flag para o usuário.
- Exemplo básico:

```powershell
Invoke-RestMethod -Uri "http://localhost:8004/evaluate?user_id=user-123&flag_name=enable-new-dashboard"
```

- Exemplo testando a distribuição matemática (A/B testing):
Simule a chamada para dois IDs de usuário distintos para observar a diferença no retorno com base na regra de porcentagem:

```bash
curl "http://localhost:8004/evaluate?user_id=user-xyz-1&flag_name=enable-new-dashboard"
curl "http://localhost:8004/evaluate?user_id=user-abc-9&flag_name=enable-new-dashboard"
```

- O fluxo interno faz:
  - consulta a flag no `flag-service`
  - consulta a regra no `targeting-service`
  - usa Redis para cache
  - envia um evento para a fila SQS local

### analytics-service

`GET /health`
- Health check do worker.
- Este serviço não expõe API de negócio.
- Ele fica consumindo mensagens da fila SQS local e gravando os eventos no DynamoDB Local.

```powershell
Invoke-RestMethod -Uri http://localhost:8005/health
```

## Comandos úteis

Ver logs do serviço de avaliação:

```powershell
docker compose -f .\fase-2-local\docker-compose.yml logs -f evaluation-service
```

Ver logs do worker de analytics:

```powershell
docker compose -f .\fase-2-local\docker-compose.yml logs -f analytics-service
```

Consultar itens gravados no DynamoDB Local:

```powershell
docker run --rm --network fase-2-local_default -e AWS_ACCESS_KEY_ID=dummy -e AWS_SECRET_ACCESS_KEY=dummy -e AWS_REGION=us-east-1 amazon/aws-cli:2.15.57 dynamodb scan --table-name ToggleMasterAnalytics --endpoint-url http://dynamodb-local:8000
```

## Encerrando o ambiente

```powershell
docker compose -f .\fase-2-local\docker-compose.yml down
```
