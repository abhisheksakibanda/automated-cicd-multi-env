#!/bin/bash
cd /home/ec2-user/app/app
nohup python3 app.py > /dev/null 2>&1 &
