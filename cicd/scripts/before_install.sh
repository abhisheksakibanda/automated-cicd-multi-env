#!/bin/bash
sudo systemctl stop flaskapp || true
rm -rf /home/ec2-user/app
