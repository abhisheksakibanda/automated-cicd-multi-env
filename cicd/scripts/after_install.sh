#!/bin/bash
set -e

cd /home/ec2-user/app/app

PYTHON_BIN="/usr/bin/python3.12"

# Create venv explicitly with Python 3.12
$PYTHON_BIN -m venv venv

source venv/bin/activate

python --version
which python

pip install --upgrade pip setuptools wheel
#pip install -r requirements.txt

echo "Fixing ownership for application files..."
chown -R ec2-user:ec2-user /home/ec2-user
