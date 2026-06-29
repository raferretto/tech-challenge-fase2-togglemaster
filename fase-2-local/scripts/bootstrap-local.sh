#!/bin/sh
set -eu

SQS_ENDPOINT_URL="${AWS_SQS_ENDPOINT_URL:-http://elasticmq:9324}"
DYNAMODB_ENDPOINT_URL="${AWS_DYNAMODB_ENDPOINT_URL:-http://dynamodb-local:8000}"
SQS_QUEUE_NAME="${AWS_SQS_QUEUE_NAME:-togglemaster-evaluation-events}"
DYNAMODB_TABLE_NAME="${AWS_DYNAMODB_TABLE:-ToggleMasterAnalytics}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo "Waiting for SQS emulator at ${SQS_ENDPOINT_URL}..."
until aws --region "${AWS_REGION}" --endpoint-url "${SQS_ENDPOINT_URL}" sqs list-queues >/dev/null 2>&1; do
  sleep 2
done

echo "Waiting for DynamoDB Local at ${DYNAMODB_ENDPOINT_URL}..."
until aws --region "${AWS_REGION}" --endpoint-url "${DYNAMODB_ENDPOINT_URL}" dynamodb list-tables >/dev/null 2>&1; do
  sleep 2
done

echo "Creating SQS queue ${SQS_QUEUE_NAME}..."
aws --region "${AWS_REGION}" --endpoint-url "${SQS_ENDPOINT_URL}" sqs create-queue \
  --queue-name "${SQS_QUEUE_NAME}" >/dev/null

echo "Ensuring DynamoDB table ${DYNAMODB_TABLE_NAME} exists..."
if ! aws --region "${AWS_REGION}" --endpoint-url "${DYNAMODB_ENDPOINT_URL}" dynamodb describe-table \
  --table-name "${DYNAMODB_TABLE_NAME}" >/dev/null 2>&1; then
  aws --region "${AWS_REGION}" --endpoint-url "${DYNAMODB_ENDPOINT_URL}" dynamodb create-table \
    --table-name "${DYNAMODB_TABLE_NAME}" \
    --attribute-definitions AttributeName=event_id,AttributeType=S \
    --key-schema AttributeName=event_id,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 >/dev/null

  aws --region "${AWS_REGION}" --endpoint-url "${DYNAMODB_ENDPOINT_URL}" dynamodb wait table-exists \
    --table-name "${DYNAMODB_TABLE_NAME}"
fi

echo "Local bootstrap completed."
