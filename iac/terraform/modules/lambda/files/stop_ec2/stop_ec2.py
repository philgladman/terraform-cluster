import boto3
import logging
import botocore
import os
import jmespath

# set up simple logging
logging.getLogger().setLevel(os.environ['LOGGING_LEVEL'])

# Set Variables
region = os.environ.get('REGION')

# Set up connection to AWS EC@
ec2 = boto3.client('ec2', region_name=region)

def get_instance_ids():
    response = ec2.describe_instances(
        Filters=[
            {
                'Name': 'instance-state-name',
                'Values': ['running']
            }
        ]
    )
    instance_ids = jmespath.search('Reservations[].Instances[].InstanceId', response)

    return instance_ids

def lambda_handler(event, context):
    """When triggered, the lambda handler will stop all Running EC2 Instances"""
    instance_ids = get_instance_ids()
    if instance_ids:
        for instance in instance_ids:
            try:
                logging.info(" Attempting to stop EC2 Instance: %s", instance)
                response = ec2.stop_instances(InstanceIds=[instance])
                print(response, "\n")
            except botocore.exceptions.ClientError as error:
                logging.error(
                    " Cannot stop EC2 Instance: %s\n%s", instance,
                        error.response['Error']['Message']
                )
    else:
        logging.info(" There are no Running EC2 Instances to stop")
