#!/bin/bash
set -e

cd /home/ec2-user/app/app

# Activate Python 3.12 virtual environment
source venv/bin/activate

# Start the app using venv Python
nohup python app.py > /home/ec2-user/app/app/app.log 2>&1 &
