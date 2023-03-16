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

install_cloudwatch_agent(){
  echo "Installing cloudwatch Agent"
  sudo yum install -y wget
  wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
  rpm -U ./amazon-cloudwatch-agent.rpm

  # Get name of this instance
  echo "setting instance variables"
  TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
  INSTANCE_ID=`curl -H "X-aws-ec2-metadata-token: $${TOKEN}" -v http://169.254.169.254/latest/meta-data/instance-id`
  INSTANCE_NAME=$(aws ec2 describe-instances --instance-ids $${INSTANCE_ID} --query "Reservations[].Instances[].Tags[?Key=='Name'].Value" --output text)
  INSTANCE_HOSTNAME=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/hostname)

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
          "resources": ["*"],
          "measurement": ["disk_used_percent"],
          "ignore_file_system_types": ["sysfs", "devtmpfs", "tmpfs", "overlay"]
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
              "file_path": "/var/log/boot.log*",
              "log_group_name": "${LOG_GROUP_NAME}",
              "log_stream_name": "$${INSTANCE_NAME}/{instance_id}/var/log/boot.log*",
              "timestamp_format": "%H: %M: %S%y%b%-d",
              "retention_in_days": ${LOG_RETENTION_IN_DAYS}
            },
            {
              "file_path": "/var/log/dmesg",
              "log_group_name": "${LOG_GROUP_NAME}",
              "log_stream_name": "$${INSTANCE_NAME}/{instance_id}/var/log/dmesg",
              "timestamp_format": "%H: %M: %S%y%b%-d"
            },
            {
              "file_path": "/var/log/secure",
              "log_group_name": "${LOG_GROUP_NAME}",
              "log_stream_name": "$${INSTANCE_NAME}/{instance_id}/var/log/secure",
              "timestamp_format": "%H: %M: %S%y%b%-d"
            },
            {
              "file_path": "/var/log/messages",
              "log_group_name": "${LOG_GROUP_NAME}",
              "log_stream_name": "$${INSTANCE_NAME}/{instance_id}/var/log/messages",
              "timestamp_format": "%H: %M: %S%y%b%-d"
            },
            {
              "file_path": "/var/log/cron*",
              "log_group_name": "${LOG_GROUP_NAME}",
              "log_stream_name": "$${INSTANCE_NAME}/{instance_id}/var/log/cron*",
              "timestamp_format": "%H: %M: %S%y%b%-d"
            },
            {
              "file_path": "/var/log/cloud-init-output.log",
              "log_group_name": "${LOG_GROUP_NAME}",
              "log_stream_name": "$${INSTANCE_NAME}/{instance_id}/var/log/cloud-init-output.log",
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

  # Install and Configure Cloudwatch agent from local config file
  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/home/ec2-user/cw-config.json -s
  echo 'cloudwatch Agent Installation Complete'

  # Create EBS Alarms for each partition on each EBS volume
  echo "creating variables for ebs usage cloudwatch alarm"

  partition_count=$(df -hT | grep -v "tmpfs" | grep -v "overlay" | grep -v "nfs" | grep -v "/var/lib/kubelet/pods" | wc -l)

  for i in $(seq 2 $${partition_count})
  do
    echo "##############################"

    partition_name=$(df -hT | grep -v "tmpfs" | grep -v "overlay" | grep -v "nfs" | grep -v "/var/lib/kubelet/pods" | sed -n "$${i}"p | tr -s ' ' | cut -d " " -f 1 | cut -d "/" -f 3)
    partition_fs_type=$(df -hT | grep -v "tmpfs" | grep -v "overlay" | grep -v "nfs" | grep -v "/var/lib/kubelet/pods" | sed -n "$${i}"p | tr -s ' ' | cut -d " " -f 2)
    partition_path=$(df -hT | grep -v "tmpfs" | grep -v "overlay" | grep -v "nfs" | grep -v "/var/lib/kubelet/pods" | sed -n "$${i}"p | tr -s ' ' | cut -d " " -f 7)
    echo "Creating Cloudwatch Alarm for partition: $${partition_name}, of fstype: $${partition_fs_type}, at path: $${partition_path}"

    aws cloudwatch put-metric-alarm \
        --alarm-name "$${INSTANCE_NAME}-ebs-alarm-$${INSTANCE_ID}-$${partition_name}" \
        --alarm-description "Alarms when the partition $${partition_name} in the EBS Volume attached to instance $${INSTANCE_NAME}/$${INSTANCE_ID} reaches 75% Disk Utilization" \
        --namespace "${METRICS_NAMESPACE}" \
        --metric-name disk_used_percent \
        --period 300 \
        --threshold 75 \
        --statistic Average \
        --comparison-operator GreaterThanOrEqualToThreshold \
        --dimensions Name=path,Value=$${partition_path} \
        Name=host,Value=$${INSTANCE_HOSTNAME} \
        Name=device,Value=$${partition_name} \
        Name=fstype,Value=$${partition_fs_type} \
        --evaluation-periods 1 \
        --alarm-actions "${SNS_TOPIC_ARN}"

    echo "##############################"
  done
}
install_cloudwatch_agent

# Download kubectl and mnake kube dir
curl -LO "https://dl.k8s.io/release/v1.23.5/bin/linux/amd64/kubectl"
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