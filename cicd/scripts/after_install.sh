#!/bin/bash
set -e

which python3
python3 --version
pip3 --version

cd /home/ec2-user/app/app/
pip3 install -r requirements.txt
