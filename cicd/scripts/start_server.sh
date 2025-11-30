#!/bin/bash
cd /home/ec2-user/app
nohup python3 app.py > /dev/null 2>&1 &
