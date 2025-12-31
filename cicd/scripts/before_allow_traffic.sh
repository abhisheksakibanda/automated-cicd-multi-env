#!/bin/bash
set -e

echo "BeforeAllowTraffic: Preparing for traffic shift..."
echo "Current time: $(date)"

echo "Performing final health check before allowing traffic..."

for i in {1..10}; do
    if curl -sf http://localhost:5000/health > /dev/null; then
        echo "Health check passed (attempt $i/10)"
        exit 0
    fi

    echo "Health check failed (attempt $i/10), retrying..."
    sleep 3
done

echo "ERROR: Application failed health checks before traffic shift"
exit 1
