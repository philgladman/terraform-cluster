#!/bin/bash

echo "starting userdata"

## ## install tools
## echo "installing tools"
## sudo yum install -y curl wget unzip

start_rke2_server{
  echo "Disabling nm-cloud-setup..."
  systemctl disable nm-cloud-setup.service
  systemctl disable nm-cloud-setup.timer
  
  echo "Enabling rke2-server..."
  systemctl enable rke2-server
  echo "Performing daemon-reload"
  systemctl daemon-reload
  echo "Starting rke2-server"
  systemctl start rke2-server
}

install_cw_ssm_agent{
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
}

start_rke2_server
install_cw_ssm_agent

echo "userdata complete"