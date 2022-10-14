import boto3
import jmespath
import paramiko
import os

# make this into env variable
AWS_REGION = 'us-east-1'

# establish ec2 and ssm client session
EC2_CLIENT = boto3.client('ec2', region_name=AWS_REGION)
SSM_CLIENT = boto3.client('ssm', region_name=AWS_REGION)


def lambda_handler():
    # Set up ssh client and connect to bastion
    ssh = paramiko.SSHClient()
    mgmt_bastion_public_ip = get_mgmt_bastion_ip()
    sbx_bastion_public_ip = get_sbx_bastion_ip()

    # attempt to retrieve the ec2 user pem key
    get_ec2_pem_key()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    pkey = paramiko.RSAKey.from_private_key_file("/tmp/test.txt")
    ssh.connect(mgmt_bastion_public_ip, username="ec2-user", pkey=pkey)

    # Run command 1 on the bastion and output response
    github_username = "philgladman"
    github_pat = "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"
    github_command = "git clone --branch phil-lambda https://" + github_username + \
        ":" + github_pat + "@github.com/raft-tech/tcode.git /tmp/tcode"
    stdin, stdout, stderr = ssh.exec_command(github_command)
    outlines = stdout.readlines()
    resp = ''.join(outlines)
    print(resp)

    # Run command 2 on the bastion and output response
    stdin, stdout, stderr = ssh.exec_command('cat /tmp/tcode/k8s/deploy.sh')
    outlines = stdout.readlines()
    resp = ''.join(outlines)
    print(resp)

    # Run command 3 on the bastion and output response
    stdin, stdout, stderr = ssh.exec_command('rm -rf /tmp/tcode')
    outlines = stdout.readlines()
    resp = ''.join(outlines)
    print(resp)

    # Close ssh connection
    ssh.close()

    # Delete the master key file contents from the lambda box
    if os.path.exists("/tmp/test.txt"):
        os.remove("/tmp/test.txt")
    else:
        print("File does not exist!")


def get_sbx_bastion_ip():
    """Get sandbox bastion public ip"""

    sbx_bastion = EC2_CLIENT.describe_instances(Filters=[
        {'Name': 'tag:Name',
         'Values': ['raft-tcode-il2-sbx-bastion']
         },
    ],)
    sbx_bastion_public_ip = jmespath.search(
        'Reservations[].Instances[].PublicIpAddress', sbx_bastion)
    sbx_bastion_public_ip = sbx_bastion_public_ip[0]

    return sbx_bastion_public_ip


def get_mgmt_bastion_ip():
    """Get mgmt bastion public ip"""

    mgmt_bastion = EC2_CLIENT.describe_instances(Filters=[
        {'Name': 'tag:Name',
         'Values': ['raft-tcode-il2-mgmt-bastion']
         },
    ],)

    mgmt_bastion_public_ip = jmespath.search(
        'Reservations[].Instances[].PublicIpAddress', mgmt_bastion)
    mgmt_bastion_public_ip = mgmt_bastion_public_ip[0]

    return mgmt_bastion_public_ip


def get_ec2_pem_key():
    """Get private master key from AWS SSM Parameter Store and write to /tmp/test.txt on the lambda box"""

    master_key_parameter = SSM_CLIENT.get_parameter(
        Name='raft-tcode-master-ec2-user-key-private',
        WithDecryption=True
    )
    try:
        master_key = jmespath.search('Parameter.Value', master_key_parameter)
        with open("/tmp/test.txt", "w") as f:
            f.write(master_key)
            print("Key has been written to file")
    except IOError as e:
        print("I/0 error ({0}): {1}".format(e.errno, e.strerror))

# def get_phil_kubeconfig():


if __name__ == "__main__":
    lambda_handler()
