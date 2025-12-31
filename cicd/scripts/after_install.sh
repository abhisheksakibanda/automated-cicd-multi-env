#!/bin/bash
set -e

cd /home/ec2-user/app/app

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
