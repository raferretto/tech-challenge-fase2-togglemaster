#!/bin/bash
set -e

echo "======================================"
echo "    ToggleMaster AWS Setup Script     "
echo "======================================"

cd ../terraform

echo "1. Initializing Terraform..."
terraform init

echo "2. Applying Terraform (Creating AWS Infrastructure & EKS)..."
terraform apply -auto-approve -parallelism=30

echo "2.5 Checking for kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo "kubectl installed successfully!"
else
    echo "kubectl is already installed."
fi

echo "3. Updating local kubeconfig..."
KUBECONFIG_CMD=$(terraform output -raw kubeconfig_command)
eval $KUBECONFIG_CMD

echo "4. Generating Kubernetes Secrets from Terraform Outputs..."

# Function to safely get base64 terraform outputs and decode them
get_tf_b64_output() {
  terraform output -raw $1 | base64 --decode
}

# Create k8s directory for auto-generated secrets if it doesn't exist
mkdir -p ../k8s/generated

cat <<EOF > ../k8s/generated/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: auth-service-secret
  namespace: togglemaster
type: Opaque
stringData:
  DATABASE_URL: "$(get_tf_b64_output auth_service_database_url_b64)"
  MASTER_KEY: "$(get_tf_b64_output auth_service_master_key_b64)"
  SERVICE_API_KEY: "$(get_tf_b64_output service_api_key_b64)"
---
apiVersion: v1
kind: Secret
metadata:
  name: flag-service-secret
  namespace: togglemaster
type: Opaque
stringData:
  DATABASE_URL: "$(get_tf_b64_output flag_service_database_url_b64)"
  SERVICE_API_KEY: "$(get_tf_b64_output service_api_key_b64)"
---
apiVersion: v1
kind: Secret
metadata:
  name: targeting-service-secret
  namespace: togglemaster
type: Opaque
stringData:
  DATABASE_URL: "$(get_tf_b64_output targeting_service_database_url_b64)"
  SERVICE_API_KEY: "$(get_tf_b64_output service_api_key_b64)"
---
apiVersion: v1
kind: Secret
metadata:
  name: evaluation-service-secret
  namespace: togglemaster
type: Opaque
stringData:
  REDIS_URL: "$(get_tf_b64_output evaluation_service_redis_url_b64)"
  AWS_SQS_URL: "$(get_tf_b64_output evaluation_service_sqs_url_b64)"
  SERVICE_API_KEY: "$(get_tf_b64_output service_api_key_b64)"
---
apiVersion: v1
kind: Secret
metadata:
  name: analytics-service-secret
  namespace: togglemaster
type: Opaque
stringData:
  AWS_SQS_URL: "$(get_tf_b64_output analytics_service_sqs_url_b64)"
  SERVICE_API_KEY: "$(get_tf_b64_output service_api_key_b64)"
EOF

echo "5. Generating ServiceAccounts and KEDA Manifests..."
KEDA_ROLE_ARN=$(terraform output -raw keda_sqs_role_arn)
AWS_REGION=$(terraform output -raw aws_region)
SQS_URL=$(terraform output -raw sqs_queue_url)

cat <<EOF > ../k8s/generated/analytics-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: analytics-service-sa
  namespace: togglemaster
  annotations:
    eks.amazonaws.com/role-arn: \${KEDA_ROLE_ARN}
EOF

cat <<EOF > ../k8s/generated/keda.yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: keda-aws-credentials
  namespace: togglemaster
spec:
  podIdentity:
    provider: aws
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: analytics-service-scaler
  namespace: togglemaster
spec:
  scaleTargetRef:
    name: analytics-service
  minReplicaCount: 1
  maxReplicaCount: 5
  triggers:
  - type: aws-sqs-queue
    authenticationRef:
      name: keda-aws-credentials
    metadata:
      queueURL: \${SQS_URL}
      queueLength: "5"
      awsRegion: \${AWS_REGION}
      identityOwner: pod
EOF

echo "6. Applying Kubernetes Manifests..."

# Configure ECR images in kustomize
ACCOUNT_ID=$(terraform output -raw account_id)
REGION=$(terraform output -raw aws_region)
ECR_BASE="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Updating Kustomize with ECR URIs..."
cd ../k8s
# Remove existing images block if it exists
sed -i '/^images:/,$d' kustomization.yaml

# This edits kustomization.yaml to replace REPLACE_ME_ECR_URI with actual ECR urls
cat <<EOF >> kustomization.yaml

images:
  - name: REPLACE_ME_ECR_URI/auth-service
    newName: ${ECR_BASE}/auth-service
    newTag: latest
  - name: REPLACE_ME_ECR_URI/flag-service
    newName: ${ECR_BASE}/flag-service
    newTag: latest
  - name: REPLACE_ME_ECR_URI/targeting-service
    newName: ${ECR_BASE}/targeting-service
    newTag: latest
  - name: REPLACE_ME_ECR_URI/evaluation-service
    newName: ${ECR_BASE}/evaluation-service
    newTag: latest
  - name: REPLACE_ME_ECR_URI/analytics-service
    newName: ${ECR_BASE}/analytics-service
    newTag: latest
EOF
cd ../scripts

kubectl apply -f ../k8s/namespace.yaml
kubectl apply -f ../k8s/generated/secrets.yaml
kubectl apply -f ../k8s/generated/analytics-sa.yaml
kubectl apply -f ../k8s/generated/keda.yaml
kubectl apply -k ../k8s

echo "======================================"
echo "    Setup Completed Successfully!     "
echo "======================================"
