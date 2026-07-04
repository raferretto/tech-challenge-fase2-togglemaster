#!/bin/bash
set -e

echo "======================================"
echo "   ToggleMaster AWS Destroy Script    "
echo "======================================"

echo "1. Deleting Kubernetes Manifests..."
if [ -d "../k8s" ]; then
  kubectl delete -k ../k8s --ignore-not-found=true --wait=false || true
fi

if [ -f "../k8s/generated/secrets.yaml" ]; then
  kubectl delete -f ../k8s/generated/secrets.yaml --ignore-not-found=true --wait=false || true
  rm -f ../k8s/generated/secrets.yaml
fi

echo "2. Destroying Terraform Infrastructure..."
cd ../terraform
terraform destroy -auto-approve -parallelism=30

echo "======================================"
echo "    Destroy Completed Successfully!   "
echo "======================================"
