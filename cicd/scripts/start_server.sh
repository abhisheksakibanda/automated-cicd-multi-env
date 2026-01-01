#!/bin/bash
set -e

set -a
source /etc/myapp.env
set +a

cd /home/ec2-user/app/app
source venv/bin/activate

echo "Starting app with APP_ENV=$APP_ENV at $(date)" >> app.log

nohup python app.py >> app.log 2>&1 &
