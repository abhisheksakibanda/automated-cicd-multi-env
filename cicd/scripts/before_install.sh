#!/bin/bash
set -e

PYTHON_VERSION="3.12.10"
PYTHON_BIN="/usr/local/bin/python3.12"

echo "Stopping application if running..."
sudo systemctl stop flaskapp || true

echo "Cleaning previous application files..."
rm -rf /home/ec2-user/app

# ---- Python 3.12 bootstrap (idempotent) ----
if [ ! -x "$PYTHON_BIN" ]; then
  echo "Python $PYTHON_VERSION not found. Installing..."

  sudo yum update -y
  sudo yum groupinstall -y "Development Tools"
  sudo yum install -y \
    openssl-devel \
    bzip2-devel \
    libffi-devel \
    zlib-devel \
    wget

  cd /usr/src
  sudo wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
  sudo tar xzf Python-${PYTHON_VERSION}.tgz

  cd Python-${PYTHON_VERSION}
  sudo ./configure --enable-optimizations
  sudo make altinstall

  echo "Python $PYTHON_VERSION installed successfully"
else
  echo "Python 3.12 already installed. Skipping."
fi

$PYTHON_BIN --version
