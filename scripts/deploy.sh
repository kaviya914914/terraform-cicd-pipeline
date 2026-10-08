#!/bin/bash
set -eo pipefail
IP=$1
IMAGE=$2
REGION=ap-south-1
REGISTRY=${IMAGE%%/*}
SSH="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $HOME/.ssh/cicd-key ubuntu@$IP"

# wait until the server is up and Docker is ready
until $SSH 'sudo docker info' >/dev/null 2>&1; do
  echo "waiting for server..."
  sleep 10
done

# Jenkins gets the ECR password and sends it to the server over SSH
aws ecr get-login-password --region $REGION | $SSH "sudo docker login --username AWS --password-stdin $REGISTRY"

$SSH "sudo docker pull $IMAGE && (sudo docker rm -f app || true) && sudo docker run -d --name app -p 80:5000 $IMAGE"
