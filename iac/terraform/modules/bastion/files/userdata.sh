#!/bin/bash

echo "starting userdata"

## install tools
echo "installing tools"
sudo yum install -y curl wget unzip git

# download awscli
echo "installing awscli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Download Cloudwatch agent
echo "Installing cloudwatch Agent"
sudo yum install -y wget
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Install and Configure Cloudwatch agent from ssm parameter store config file
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c ssm:${ssm_cloudwatch_config} -s
echo 'cloudwatch Agent Installation Complete'

echo "userdata complete"