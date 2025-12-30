#!/bin/bash
set -e

echo "PWD:"
pwd

echo "Contents of /home/ec2-user/app:"
ls -la /home/ec2-user/app

echo "Contents of /home/ec2-user/app/app:"
ls -la /home/ec2-user/app/app

pip3 install -r /home/ec2-user/app/app/requirements.txt
