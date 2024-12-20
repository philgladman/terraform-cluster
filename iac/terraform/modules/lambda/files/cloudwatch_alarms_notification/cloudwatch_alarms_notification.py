import boto3
import logging
import botocore
import os
from datetime import datetime, timedelta


# Set Variables
logging.getLogger().setLevel(os.environ['LOGGING_LEVEL'])
region = os.environ.get('REGION')
aws_partition = os.environ.get('AWS_PARTITION')
sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')

if "gov" in aws_partition:
    aws_url = "amazon" + aws_partition
else:
    aws_url = aws_partition + ".amazon"

def format_time(event_time):
    """Inputs the time received from AWS and reformats & converts to CST time. The newly formatted time will look like this, 14:34:18 CST on Aug 04, 2023"""
    unformatted_time = datetime.strptime(event_time.split(".")[0],'%Y-%m-%dT%H:%M:%S')
    unformatted_central_time = unformatted_time - timedelta(hours=5)
    formatted_central_time = datetime.strftime(unformatted_central_time,'%H:%M:%S CST on %b %d, %Y')

    return formatted_central_time

def send_email_alert(name, time, description, url):
    """Publish an alerting email message to the SNS Topic"""
    sns = boto3.client('sns', region_name=region)
    message="""
ATTENTION - AWS ALARM TRIGGERD,\n
NAME:   --------------  {}
TIME:     -------------- {}
DESCRIPTION: ---- {}
URL:      --------------  {}\n\n\n
(end of message)
""".format(name, time, description, url)
    try:
        sns_response = sns.publish(
            TopicArn=sns_topic_arn,
            Message=message,
            Subject="AWS ALARM - " + name,
            MessageStructure="string"
        )
        logging.info(" Publishing email for %s alert to SNS Topic ARN: %s. Message ID: %s", 
            name, sns_topic_arn, sns_response['MessageId']
        )
    except botocore.exceptions.ClientError as error:
        logging.error(
            " Cannot publish to SNS Topic ARN: %s\n%s", sns_topic_arn,
                error.response['Error']['Message']
        )

def lambda_handler(event, context):
    """When triggered, the lambda handler send an an Email Alert"""
    print("#"*25)
    alarm_name = event['alarmData']['alarmName']
    alarm_time = format_time(event['time'])
    alarm_description = event['alarmData']['configuration']['description']
    alarm_url = "https://" + region + ".console." + aws_url + ".com/cloudwatch/home?region=" + region + "#alarmsV2:alarm/" + alarm_name
    send_email_alert(alarm_name, alarm_time, alarm_description, alarm_url)
    print("#"*25)
