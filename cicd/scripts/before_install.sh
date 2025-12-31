#!/bin/bash
set -e

echo "Stopping application if running..."
sudo systemctl stop flaskapp || true

echo "Cleaning previous application files..."
rm -rf /home/ec2-user/app

echo "Ensuring Python and pip are installed..."
sudo dnf update -y
sudo dnf install -y python3 python3-pip

echo "Verifying Python runtime..."
python3 --version
pip3 --version
