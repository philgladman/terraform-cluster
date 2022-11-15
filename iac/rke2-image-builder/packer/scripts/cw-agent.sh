#!/usr/bin/env bash

# enable the epel release
#echo "updating server"
#yum update -y 

# Install Cloudwatch agent
echo "Installing cloudwatch Agent"
sudo yum install -y wget
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create cloudwatch config file
cat >"/tmp/cw-config.json"<<'EOF'
{
  "agent": {
    "metrics_collection_interval": 10
  },
  "metrics": {
    "namespace": "CloudWatch-Agent-TEST-Metrics",
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
            "log_group_name": "ec2-/var/log/messages",
            "timestamp_format": "%H: %M: %S%y%b%-d"
          }
        ]
      }
    },
    "log_stream_name": "{instance_id}"
  }
}
EOF

# Use cloudwatch config from SSM
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/tmp/cw-config.json -s

echo 'cloudwatch Agent Installation Complete'
