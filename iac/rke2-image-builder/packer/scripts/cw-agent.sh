# Download Cloudwatch agent
echo "Installing cloudwatch Agent"
sudo yum install -y wget
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create cloudwatch config file
echo "creating cloudwatch agent config file"
cat >"/home/ec2-user/cw-config.json"<<'EOF'
{
  "agent": {
    "metrics_collection_interval": 10
  },
  "metrics": {
    "namespace": "METRICS_NAMESPACE_PLACEHOLDER",
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
            "log_group_name": "LOG_GROUP_NAME_PLACEHOLDER",
            "timestamp_format": "%H: %M: %S%y%b%-d"
          }
        ]
      }
    },
    "log_stream_name": "INSTANCE_NAME_PLACEHOLDER/{instance_id}"
  }
}
EOF

