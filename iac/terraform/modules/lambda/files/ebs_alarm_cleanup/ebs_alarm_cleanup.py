import boto3
import logging
import botocore
import os
import jmespath

# set up simple logging
logging.getLogger().setLevel(os.environ['LOGGING_LEVEL'])

# Set Variables
region = os.environ.get('REGION')

# Set up connection to AWS Cloudwatch
cloudwatch = boto3.client('cloudwatch', region_name=region)

response = cloudwatch.describe_alarms()
alarms_list = jmespath.search('MetricAlarms[].[AlarmName,StateValue]', response)
alarms_len = len(alarms_list)

def lambda_handler(event, context):
    """When triggered, the lambda handler will loop through all CloudWatch Alarms, and delete all the ebs related alarms that are no longer in use"""
    for i in range(alarms_len):
        if "ebs" in alarms_list[i][0]:
            if "INSUFFICIENT_DATA" in alarms_list[i][1]:
                try:
                    response = cloudwatch.delete_alarms(
                        AlarmNames=[
                            alarms_list[i][0],
                        ]
                    )
                    logging.info(" Deleting Cloudwatch Alarm: %s that is in state: %s\n%s", 
                        alarms_list[i][0], alarms_list[i][1], response
                    )
                except botocore.exceptions.ClientError as error:
                    logging.error(
                        " Cannot Delete Cloudwatch Alarm: %s that is in state: %s\n%s", 
                            alarms_list[i][0], alarms_list[i][1], error.response['Error']['Message']
                    )
            else:
                logging.info(" NOT deleting Cloudwatch Alarm: %s that is still active, and is in state: %s", 
                    alarms_list[i][0], alarms_list[i][1]
                )
