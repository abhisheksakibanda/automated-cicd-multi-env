#!/bin/bash
set -e

cd /home/ec2-user/app/app
source venv/bin/activate

nohup python app.py > /home/ec2-user/app/app/app.log 2>&1 &
