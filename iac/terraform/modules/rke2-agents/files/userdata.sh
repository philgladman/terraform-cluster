#!/bin/bash

echo "starting userdata"

export TYPE="${type}"

# info logs the given argument at info log level.
info() {
  echo "[INFO] " "$@"
}

# warn logs the given argument at warn log level.
warn() {
  echo "[WARN] " "$@" >&2
}

# fatal logs the given argument at fatal log level.
fatal() {
  echo "[ERROR] " "$@" >&2
  exit 1
}

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

## install tools
echo "installing tools"
sudo yum install -y curl wget unzip git vim

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

##############

config() {
  mkdir -p "/etc/rancher/rke2"
#   if [ $TYPE == "server" ]; then
#     cat <<EOF > "/etc/rancher/rke2/config.yaml"
# # Additional user defined configuration
# cluster-dns: "20.43.0.10"
# cluster-cidr: "20.42.0.0/16"
# service-cidr: "20.43.0.0/16"
# disable: rke2-ingress-nginx
# secrets-encryption: true
# # commenting out profile for now, as we need to work on psp
# # profile: cis-1.6
# selinux: true
# cni: canal
# audit-policy-file: /etc/rancher/rke2/audit-policy.yaml
# etcd-arg:
#   - listen-metrics-urls=http://0.0.0.0:2381
# kube-apiserver-arg:
#   - audit-log-format=json
#   - audit-log-maxage=5
#   - audit-log-maxbackup=5
#   - audit-log-maxsize=256
#   - audit-log-path=/var/lib/rancher/rke2/server/logs/audit.log
# kube-controller-manager-arg:
#   - bind-address=0.0.0.0
# kube-scheduler-arg:
#   - bind-address=0.0.0.0
# EOF
# fi
}

put_token() {
  aws configure set default.region "$(curl -s http://169.254.169.254/latest/meta-data/placement/region)"

  # Validate aws caller identity, fatal if not valid
  if ! aws sts get-caller-identity 2>/dev/null; then
    fatal "No valid aws caller identity"
  fi

  sudo aws s3 cp /var/lib/rancher/rke2/server/node-token "s3://${token_bucket}/generated-token"
  echo "copied newly generated cluster token to s3 bucket"
}

fetch_token() {
  info "Fetching rke2 join token..."

  aws configure set default.region "$(curl -s http://169.254.169.254/latest/meta-data/placement/region)"

  # Validate aws caller identity, fatal if not valid
  if ! aws sts get-caller-identity 2>/dev/null; then
    fatal "No valid aws caller identity"
  fi

  # Either
  #   a) fetch token from s3 bucket
  #   b) fail
  #if token=$(aws s3 cp "s3://${token_bucket}/${token_object}" - 2>/dev/null);then
  if token=$(aws s3 cp "s3://${token_bucket}/generated-token" - 2>/dev/null);then
    info "Found token from s3 object"
  else
    fatal "Could not find cluster token from s3"
  fi

  echo "token: $${token}" >> "/etc/rancher/rke2/config.yaml"
}

get_server_url() {
  server_url=$(aws ec2 describe-instances --filters Name=tag:Name,Values=phil-dev-controlplane --query "Reservations[].Instances[].PrivateIpAddress" --output text)
}

append_config() {
  echo "$1" >> "/etc/rancher/rke2/config.yaml"
}

upload() {
  # Wait for kubeconfig to exist, then upload to s3 bucket
  retries=10

  while [ ! -f /etc/rancher/rke2/rke2.yaml ]; do
    sleep 10
    if [ "$retries" == 0 ]; then
      fatal "Failed to create kubeconfig"
    fi
    ((retries--))
  done

  # Replace localhost with server url and upload to s3 bucket
  get_server_url
  sed "s/127.0.0.1/$server_url/g" /etc/rancher/rke2/rke2.yaml | aws s3 cp - "s3://${token_bucket}/rke2.yaml"
  info "uploaded kubeconfig to s3 bucket"
}

start_rke2() {
  echo "Disabling nm-cloud-setup..."
  systemctl disable nm-cloud-setup.service
  systemctl disable nm-cloud-setup.timer

  if [ $TYPE == "server" ]; then
    echo "Enabling rke2-server..."
    systemctl enable rke2-server
    echo "Performing daemon-reload"
    systemctl daemon-reload
    echo "Starting rke2-server"
    systemctl start rke2-server

    export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
    export PATH=$PATH:/var/lib/rancher/rke2/bin

    put_token
    upload
  fi
  
  if [ $TYPE == "agent" ]; then
    fetch_token
    get_server_url
    append_config "server: https://$server_url:9345"
    
    echo "Enabling rke2-agent..."
    systemctl enable rke2-agent
    echo "Performing daemon-reload"
    systemctl daemon-reload
    echo "Starting rke2-agent"
    systemctl start rke2-agent
  fi
}

#info "sleeping for 10 secs"
#sleep 10
config
#fetch_token
#get_server_url
#append_config 'cloud-provider-name: "aws"'
#append_config "server: https://$server_url:9345"
start_rke2

if [ $TYPE == "agent" ]; then
  instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  availability_zone=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
  cat <<EOF >> "/etc/rancher/rke2/config.yaml"
kubelet-arg:
  - "--provider-id=aws:///$availability_zone/$instance_id"
EOF
fi

info "sleeping for 5 secs before executing post_userdata"
sleep 5


echo "userdata complete"