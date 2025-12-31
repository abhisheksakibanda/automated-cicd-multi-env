#!/bin/bash
set -e

cd /home/ec2-user/app/app

python3 -m venv venv
source venv/bin/activate

python --version
which python
pip --version

pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
