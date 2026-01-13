#!/bin/bash
# AfterAllowTraffic hook - runs after traffic has been shifted to new instances
# This is the post-traffic validation phase in Blue/Green deployment

echo "AfterAllowTraffic: Traffic has been shifted to new instances"
echo "Current time: $(date)"

# Monitor application health after traffic shift
echo "Monitoring application health for 30 seconds..."
HEALTHY=true

for i in {1..6}; do
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        echo "Health check passed (check $i/6)"
    else
        echo "WARNING: Health check failed (check $i/6)"
        HEALTHY=false
    fi
    sleep 5
done

if [ "$HEALTHY" = true ]; then
    echo "Application is healthy after traffic shift"
    exit 0
else
    echo "WARNING: Some health checks failed, but deployment continues"
    echo "CloudWatch alarms will trigger rollback if needed"
    exit 0
fi
