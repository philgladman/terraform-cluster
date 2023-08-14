import os

import boto3
import jmespath
import paramiko
from scp import SCPClient


# make this into env variable
region = os.environ.get('aws_region')

# establish ec2 and ssm client session
EC2_CLIENT = boto3.client('ec2', region_name=region)
SSM_CLIENT = boto3.client('ssm', region_name=region)


def lambda_handler(event, context):
    # Set up ssh client and connect to bastion
    ssh = paramiko.SSHClient()
    bastion_public_ip = get_bastion_ip()

    # attempt to retrieve the ec2 user pem key
    get_ec2_pem_key()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    pkey = paramiko.RSAKey.from_private_key_file("/tmp/test.txt")
    ssh.connect(bastion_public_ip, username="ec2-user", pkey=pkey)
    scp = SCPClient(ssh.get_transport())

    # Run command 1 on the bastion and output response
    github_username = get_github_username()
    github_pat = get_github_pat()
    github_command = "git clone --branch phil-lambda https://" + github_username + ":" + github_pat + "@github.com/philgladman/test.git /tmp/test"
    stdin, stdout, stderr = ssh.exec_command(github_command)
    #stdin, stdout, stderr = ssh.exec_command('/bin/sh -c "echo ' + github_command + '"')
    outlines = stdout.readlines()
    resp = ''.join(outlines)
    print(resp)
    print("end of command 1")

    # Run command 2 on the bastion and output response
    get_kubeconfig_command = "aws s3 cp s3://test-bucket-phil-sully-gus/test.txt ."
    stdin, stdout, stderr = ssh.exec_command(get_kubeconfig_command)
    outlines = stdout.readlines()
    resp = ''.join(outlines)
    print(resp)
    print("end of command 2")

    # Run command 3 on the bastion and output response
    get_node_readiness_script()
    scp.put('/tmp/node-readiness.sh')
    scp.close()
    print("end of command 3")

    # Run command 4 on the bastion and output response
    stdin, stdout, stderr = ssh.exec_command('/bin/sh /home/ec2-user/node-readiness.sh')
    outlines = stdout.readlines()
    resp = ''.join(outlines)
    print(resp)
    print("end of command 4")

    # Run command 5 on the bastion and output response
    stdin, stdout, stderr = ssh.exec_command('cat /tmp/test/k8s/deploy.sh')
    outlines = stdout.readlines()
    resp = ''.join(outlines)
    print(resp)
    print("end of command 5")

    # Run command 6 on the bastion and output response
    stdin, stdout, stderr = ssh.exec_command('rm -rf /tmp/test')
    outlines = stdout.readlines()
    resp = ''.join(outlines)
    print(resp)
    print("end of command 6")

    # Run command 7 on the bastion and output response
    stdin, stdout, stderr = ssh.exec_command('rm -rf /home/ec2-user/node-readiness.sh')
    outlines = stdout.readlines()
    resp = ''.join(outlines)
    print(resp)
    print("end of command 7")


    # Close ssh connection
    ssh.close()

    # Delete the master key file contents from the lambda box
    if os.path.exists("/tmp/test.txt"):
        os.remove("/tmp/test.txt")
    else:
        print("File does not exist!")


def get_bastion_ip():
    """Get mgmt bastion public ip"""

    bastion = EC2_CLIENT.describe_instances(Filters=[
        {'Name': 'tag:Name',
         'Values': ['phil-dev-bastion']
         },
    ],)

    bastion_public_ip = jmespath.search(
        'Reservations[].Instances[].PublicIpAddress', bastion)
    bastion_public_ip = bastion_public_ip[0]

    return bastion_public_ip


def get_ec2_pem_key():
    """Get private master key from AWS SSM Parameter Store and write to /tmp/test.txt on the lambda box"""

    master_key_parameter = SSM_CLIENT.get_parameter(
        Name='phil-dev-master-key-private',
        WithDecryption=True
    )
    try:
        master_key = jmespath.search('Parameter.Value', master_key_parameter)
        with open("/tmp/test.txt", "w") as f:
            f.write(master_key)
            print("Key has been written to file")
    except IOError as e:
        print("I/0 error ({0}): {1}".format(e.errno, e.strerror))


def get_github_username():
    """Get github username from AWS SSM Parameter Store and store as env variables on lambda box"""

    github_username_parameter = SSM_CLIENT.get_parameter(
        Name='phil-dev-github-username',
        WithDecryption=True
    )
    github_username = jmespath.search(
        'Parameter.Value', github_username_parameter)
    return github_username


def get_github_pat():
    """Get github PAT from AWS SSM Parameter Store and store as env variables on lambda box"""

    github_pat_parameter = SSM_CLIENT.get_parameter(
        Name='phil-dev-github-pat',
        WithDecryption=True
    )
    github_pat = jmespath.search('Parameter.Value', github_pat_parameter)
    return github_pat


def get_node_readiness_script():
    """Get node readiness probe script from AWS SSM Parameter Store and store as a file on Lambda box"""

    node_readiness_parameter = SSM_CLIENT.get_parameter(
        Name='phil-dev-node-readiness',
        WithDecryption=True
    )

    try:
        node_readiness = jmespath.search('Parameter.Value', node_readiness_parameter)
        with open("/tmp/node-readiness.sh", "w") as f:
            f.write(node_readiness)
            print("Key has been written to file")
    except IOError as e:
        print("I/0 error ({0}): {1}".format(e.errno, e.strerror))


# if __name__ == "__main__":
#    lambda_handler()
