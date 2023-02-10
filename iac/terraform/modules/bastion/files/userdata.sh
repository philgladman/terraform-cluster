#!/bin/bash

echo "starting userdata"

## install tools
echo "installing tools"
sudo yum install -y curl wget unzip git vim jq python3

# download awscli
echo "installing awscli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

install_cloudwatch_ssm_agent(){
  echo "Installing cloudwatch Agent"
  sudo yum install -y wget
  wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
  rpm -U ./amazon-cloudwatch-agent.rpm

  # Get name of this instance
  echo "fetching instance name"
  export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
  export INSTANCE_NAME=$(aws ec2 describe-instances --instance-ids $${INSTANCE_ID} --query "Reservations[].Instances[].Tags[?Key=='Name'].Value" --output text)

  # Create cloudwatch config file
  echo "creating cloudwatch agent config file"
  cat >"/home/ec2-user/cw-config.json"<<EOF
  {
    "agent": {
      "metrics_collection_interval": 10
    },
    "metrics": {
      "namespace": "${METRICS_NAMESPACE}",
      "metrics_collected": {
        "cpu": {
          "resources": ["*"],
          "totalcpu": true,
          "measurement": ["cpu_usage_idle"]
        },
        "disk": {
          "resources": ["/", "/tmp"],
          "measurement": ["disk_used_percent"],
          "ignore_file_system_types": ["sysfs", "devtmpfs"]
        },
        "mem": {
          "measurement": ["mem_available_percent"]
        }
      },
      "aggregation_dimensions": [["InstanceId", "InstanceType"], ["InstanceId"]]
    },
    "logs": {
      "logs_collected": {
        "files": {
          "collect_list": [
            {
              "file_path": "/var/log/messages",
              "log_group_name": "${LOG_GROUP_NAME}",
              "timestamp_format": "%H: %M: %S%y%b%-d"
            }
          ]
        }
      },
      "log_stream_name": "$${INSTANCE_NAME}/{instance_id}"
    }
  }
EOF

  # # Edit values in cloudwatch agent config file
  # echo "editing cloudwatch agent config file"
  # sed -i "s|INSTANCE_NAME_PLACEHOLDER|$${INSTANCE_NAME}|g; s|LOG_GROUP_NAME_PLACEHOLDER|${LOG_GROUP_NAME}|g; s|METRICS_NAMESPACE_PLACEHOLDER|${METRICS_NAMESPACE}|g" /home/ec2-user/cw-config.json 

  # Install and Configure Cloudwatch agent from ssm parameter store config file
  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/home/ec2-user/cw-config.json -s
  echo 'cloudwatch Agent Installation Complete'
}
install_cloudwatch_ssm_agent

# Download kubectl and mnake kube dir
curl -LO curl -LO "https://dl.k8s.io/release/v1.23.5/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
mkdir -p /home/ec2-user/.kube && chown ec2-user:ec2-user -R /home/ec2-user/.kube
rm kubectl
echo "kubectl installed and kube dir created"

# Download master key from SSM Parameter store
echo -e $(aws ssm get-parameter --name ${MASTER_KEY_SSM_NAME} --with-decryption | jq '.[].Value' | cut -d '"' -f 2) > /home/ec2-user/.ssh/master-key && chown ec2-user:ec2-user /home/ec2-user/.ssh/master-key && chmod 600 /home/ec2-user/.ssh/master-key
echo "master key downloaded"

# Download Terraform
echo "installing terraform"
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform

# Download Terragrunt
echo "installing terrgrunt"
sudo wget -O /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v0.43.2/terragrunt_linux_amd64
sudo chmod +x /usr/local/bin/terragrunt


echo "userdata complete"