#!/bin/bash
set -e

echo "======================================"
echo "    ToggleMaster ECR Build & Push     "
echo "======================================"

cd ../terraform

# 1. Obter Account ID e Region do Terraform
ACCOUNT_ID=$(terraform output -raw account_id)
REGION=$(terraform output -raw aws_region)
ECR_BASE="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Logando no AWS ECR na regiao $REGION..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_BASE

# 2. Voltar para a raiz do projeto (assumindo que as pastas dos microserviços estão fora do fase-2-cloud)
cd ../..

SERVICES=("auth-service" "flag-service" "targeting-service" "evaluation-service" "analytics-service")

for SERVICE in "${SERVICES[@]}"; do
    echo "------------------------------------------------"
    echo "Construindo a imagem para: $SERVICE"
    echo "------------------------------------------------"
    
    # Verifica se a pasta do serviço existe
    if [ -d "$SERVICE" ]; then
        cd "$SERVICE"
        
        # Faz o build usando o Dockerfile da pasta
        docker build -t $SERVICE:latest .
        
        # Adiciona a tag apontando para o ECR
        docker tag $SERVICE:latest $ECR_BASE/$SERVICE:latest
        
        echo "Fazendo push da imagem $SERVICE para o ECR..."
        docker push $ECR_BASE/$SERVICE:latest
        
        cd ..
    else
        echo "AVISO: Pasta '$SERVICE' não encontrada na raiz do projeto. Verifique o caminho."
    fi
done

echo "======================================"
echo "    Todas as imagens enviadas!        "
echo "======================================"
