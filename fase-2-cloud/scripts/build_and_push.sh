#!/bin/bash
set -e

echo "======================================"
echo "    ToggleMaster ECR Build & Push     "
echo "======================================"

cd ../terraform

ACCOUNT_ID=$(terraform output -raw account_id)
REGION=$(terraform output -raw aws_region)
ECR_BASE="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Logando no AWS ECR na regiao $REGION..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_BASE

cd ../..

SERVICES=("auth-service" "flag-service" "targeting-service" "evaluation-service" "analytics-service")

for SERVICE in "${SERVICES[@]}"; do
    echo "------------------------------------------------"
    echo "Construindo a imagem para: $SERVICE"
    echo "------------------------------------------------"
    
    if [ -d "$SERVICE" ]; then
        cd "$SERVICE"
        
        docker build -t $SERVICE:latest .
        
        docker tag $SERVICE:latest $ECR_BASE/$SERVICE:latest
        
        echo "Fazendo push da imagem $SERVICE para o ECR..."
        docker push $ECR_BASE/$SERVICE:latest
        
        cd ..
    else
        echo "AVISO: Pasta '$SERVICE' nÃ£o encontrada na raiz do projeto. Verifique o caminho."
    fi
done

echo "======================================"
echo "    Todas as imagens enviadas!        "
echo "======================================"
