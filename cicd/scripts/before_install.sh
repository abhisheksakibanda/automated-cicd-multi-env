#!/bin/bash
set -e

echo "Stopping application if running..."
sudo systemctl stop flaskapp || true

echo "Cleaning previous application files..."
rm -rf /home/ec2-user/app

echo "Installing Python 3.12 if available..."
sudo dnf update -y

if sudo dnf list available python3.12 >/dev/null 2>&1; then
  sudo dnf install -y python3.12 python3.12-pip python3.12-venv
  PYTHON_BIN="/usr/bin/python3.12"
else
  echo "ERROR: python3.12 is not available in this AL2023 repo"
  exit 1
fi

echo "Verifying Python:"
$PYTHON_BIN --version
