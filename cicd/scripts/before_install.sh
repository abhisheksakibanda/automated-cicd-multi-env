#!/bin/bash
set -e

echo "Stopping application if running..."
sudo systemctl stop flaskapp || true

echo "Cleaning previous application files..."
rm -rf /home/ec2-user/app

# ---- Python 3.12 bootstrap ----
if [ ! -x /usr/local/bin/python3.12 ]; then
  echo "Python 3.12 not found. Installing..."

  sudo yum update -y
  sudo yum groupinstall -y "Development Tools"
  sudo yum install -y \
    openssl-devel \
    bzip2-devel \
    libffi-devel \
    zlib-devel \
    wget

  cd /usr/src
  sudo wget https://www.python.org/ftp/python/3.12.2/Python-3.12.2.tgz
  sudo tar xzf Python-3.12.2.tgz

  cd Python-3.12.2
  sudo ./configure --enable-optimizations
  sudo make altinstall

  echo "Python 3.12 installed successfully"
else
  echo "Python 3.12 already installed. Skipping."
fi

/usr/local/bin/python3.12 --version
