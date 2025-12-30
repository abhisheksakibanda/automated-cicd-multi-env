#!/bin/bash
set -e

cd /home/ec2-user/app/app

/usr/local/bin/python3.12 -m venv venv
source venv/bin/activate

pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
