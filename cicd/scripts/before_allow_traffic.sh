#!/bin/bash
# BeforeAllowTraffic hook - runs before traffic is shifted to new instances
# This is the pre-traffic validation phase in Blue/Green deployment

echo "BeforeAllowTraffic: Preparing for traffic shift..."
echo "Current time: $(date)"

# Verify application is running
if ! pgrep -f "python3 app.py" > /dev/null; then
    echo "ERROR: Application is not running!"
    exit 1
fi

# Perform final health check before allowing traffic
echo "Performing final health check..."
for i in {1..5}; do
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        echo "Health check passed (attempt $i/5)"
        exit 0
    fi
    echo "Health check failed (attempt $i/5), retrying..."
    sleep 2
done

echo "ERROR: Health check failed after 5 attempts"
exit 1

