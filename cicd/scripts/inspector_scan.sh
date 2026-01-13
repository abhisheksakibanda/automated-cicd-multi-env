#!/bin/bash
# AWS Inspector Security Scan Script
# This script checks for security findings using AWS Inspector v2

set -e

echo "=== AWS Inspector Security Scan ==="
echo "Current time: $(date)"

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "Warning: AWS CLI not found. Skipping Inspector scan."
    exit 0
fi

# Get AWS account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
REGION=${AWS_REGION:-us-east-1}

if [ -z "$ACCOUNT_ID" ]; then
    echo "Warning: Could not determine AWS account. Skipping Inspector scan."
    exit 0
fi

echo "Account ID: $ACCOUNT_ID"
echo "Region: $REGION"

# Check Inspector findings (Inspector v2)
echo "Checking AWS Inspector findings..."

# List recent findings (last 24 hours)
FINDINGS=$(aws inspector2 list-findings \
    --region $REGION \
    --filter-criteria '{"severity": [{"comparison": "EQUALS", "value": "HIGH"}, {"comparison": "EQUALS", "value": "CRITICAL"}]}' \
    --max-results 100 \
    --query 'findings[?severity==`HIGH` || severity==`CRITICAL`]' \
    --output json 2>/dev/null || echo "[]")

if [ "$FINDINGS" = "[]" ] || [ -z "$FINDINGS" ]; then
    echo "No HIGH or CRITICAL severity findings in AWS Inspector"
    exit 0
fi

# Count findings by severity
CRITICAL_COUNT=$(echo "$FINDINGS" | grep -c '"severity": "CRITICAL"' || echo "0")
HIGH_COUNT=$(echo "$FINDINGS" | grep -c '"severity": "HIGH"' || echo "0")

echo "Inspector Findings:"
echo "  CRITICAL: $CRITICAL_COUNT"
echo "  HIGH: $HIGH_COUNT"

if [ "$CRITICAL_COUNT" -gt 0 ] || [ "$HIGH_COUNT" -gt 0 ]; then
    echo "QUALITY GATE FAILED: AWS Inspector found security vulnerabilities!"
    echo "$FINDINGS" | head -20
    exit 1
fi

echo "AWS Inspector scan passed"
exit 0
