#!/bin/bash

echo "starting userdata"

## install tools
echo "installing tools"
sudo yum install -y curl wget unzip

# download awscli
echo "installing awscli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

echo "userdata complete"