#!/bin/bash

echo "starting userdata"

## install tools
echo "installing tools"
sudo yum install -y curl wget unzip git vim jq

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

# Get name of this instance
echo "fetching instance name"
export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
export INSTANCE_NAME=$(aws ec2 describe-instances --instance-ids $${INSTANCE_ID} --query "Reservations[].Instances[].Tags[?Key=='Name'].Value" --output text)

# Get cloudwatch agent config file
echo "fetching cloudwatch agent config file from ssm"
aws ssm get-parameter --name ${SSM_CLOUDWATCH_CONFIG} --with-decryption --query "Parameter.Value" --output text  | sed "s/INSTANCE_NAME_PLACEHOLDER/$${INSTANCE_NAME}/g" | sed "s/LOG_GROUP_NAME/\/aws\/ec2\/instances/g"  > /tmp/cw-config.json

# Install and Configure Cloudwatch agent from ssm parameter store config file
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/tmp/cw-config.json -s
echo 'cloudwatch Agent Installation Complete'

# Download kubectl and mnake kube dir
curl -LO curl -LO "https://dl.k8s.io/release/v1.23.5/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
mkdir -p /home/ec2-user/.kube && chown ec2-user:ec2-user -R /home/ec2-user/.kube
rm kubectl
echo "kubectl installed and kube dir created"

# Download master key from SSM Parameter store
echo -e $(aws ssm get-parameter --name ${MASTER_KEY_SSM_NAME} --with-decryption | jq '.[].Value' | cut -d '"' -f 2) > /home/ec2-user/.ssh/master-key && chown ec2-user:ec2-user /home/ec2-user/.ssh/master-key && chmod 600 /home/ec2-user/.ssh/master-key
echo "master key downloaded"

echo "userdata complete"