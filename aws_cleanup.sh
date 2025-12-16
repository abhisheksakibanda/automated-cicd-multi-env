#!/bin/bash

set -e

REGION=${AWS_REGION:-us-east-1}

echo "==============================="
echo " AWS DEMO CLEANUP SCRIPT"
echo " Region: $REGION"
# echo " Time: $(date)"
echo "==============================="

echo ""
echo "TERMINATING EC2 INSTANCES..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region $REGION \
  --filters Name=instance-state-name,Values=running,stopped \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

if [ -z "$INSTANCE_IDS" ]; then
  echo "No EC2 instances found."
else
  echo "Terminating instances:"
  echo "$INSTANCE_IDS"
  aws ec2 terminate-instances --region $REGION --instance-ids $INSTANCE_IDS
  echo "EC2 termination initiated."
fi

sleep 10

echo ""
echo "DELETING AUTO SCALING GROUPS..."
ASG_NAMES=$(aws autoscaling describe-auto-scaling-groups \
  --region $REGION \
  --query "AutoScalingGroups[].AutoScalingGroupName" \
  --output text)

if [ -z "$ASG_NAMES" ]; then
  echo "No Auto Scaling Groups found."
else
  for ASG in $ASG_NAMES; do
    echo "Deleting ASG: $ASG"
    aws autoscaling update-auto-scaling-group \
      --region $REGION \
      --auto-scaling-group-name "$ASG" \
      --min-size 0 --max-size 0 --desired-capacity 0

    aws autoscaling delete-auto-scaling-group \
      --region $REGION \
      --auto-scaling-group-name "$ASG" \
      --force-delete
  done
  echo "All ASGs deleted."
fi

sleep 10

echo ""
echo "DELETING LAUNCH CONFIGURATIONS..."
LC_NAMES=$(aws autoscaling describe-launch-configurations \
  --region $REGION \
  --query "LaunchConfigurations[].LaunchConfigurationName" \
  --output text)

if [ -z "$LC_NAMES" ]; then
  echo "No Launch Configurations found."
else
  for LC in $LC_NAMES; do
    echo "Deleting Launch Configuration: $LC"
    aws autoscaling delete-launch-configuration \
      --region $REGION \
      --launch-configuration-name "$LC"
  done
  echo "All Launch Configurations deleted."
fi

sleep 10

echo ""
echo "DELETING LOAD BALANCERS..."
ALB_ARNS=$(aws elbv2 describe-load-balancers \
  --region $REGION \
  --query "LoadBalancers[].LoadBalancerArn" \
  --output text)

if [ -z "$ALB_ARNS" ]; then
  echo "No Load Balancers found."
else
  for ALB in $ALB_ARNS; do
    echo "Deleting ALB: $ALB"
    aws elbv2 delete-load-balancer --region $REGION --load-balancer-arn "$ALB"
  done
  echo "All ALBs deletion initiated."
fi

sleep 15

echo ""
echo "DELETING TARGET GROUPS..."
TG_ARNS=$(aws elbv2 describe-target-groups \
  --region $REGION \
  --query "TargetGroups[].TargetGroupArn" \
  --output text)

if [ -z "$TG_ARNS" ]; then
  echo "No Target Groups found."
else
  for TG in $TG_ARNS; do
    echo "Deleting Target Group: $TG"
    aws elbv2 delete-target-group --region $REGION --target-group-arn "$TG"
  done
  echo "All Target Groups deleted."
fi

echo ""
echo "==============================="
echo " AWS CLEANUP COMPLETE"
echo "==============================="
echo ""
echo "Now verify in AWS Console:"
echo "   - EC2 → Instances"
echo "   - EC2 → Load Balancers"
echo "   - Auto Scaling → Groups"
echo ""
