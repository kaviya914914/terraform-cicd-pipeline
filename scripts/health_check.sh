#!/bin/bash
for i in $(seq 1 10); do
  if curl -fs "http://$1/health" >/dev/null; then
    echo "healthy"
    exit 0
  fi
  echo "not ready yet, retrying..."
  sleep 5
done
echo "health check FAILED"
exit 1
