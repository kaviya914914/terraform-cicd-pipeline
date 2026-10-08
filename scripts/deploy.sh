#!/bin/bash
set -e
IP=$1
IMAGE=$2
REGION=ap-south-1
REGISTRY=${IMAGE%%/*}
SSH="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $HOME/.ssh/cicd-key ubuntu@$IP"

# wait until the server has finished its startup script
until $SSH 'command -v docker && command -v aws' >/dev/null 2>&1; do
  echo "waiting for server..."
  sleep 10
done

$SSH "aws ecr get-login-password --region $REGION | sudo docker login --username AWS --password-stdin $REGISTRY \
  && sudo docker pull $IMAGE \
  && (sudo docker rm -f app || true) \
  && sudo docker run -d --name app -p 80:5000 $IMAGE"
