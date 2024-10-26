import boto3
import logging
import botocore
import os
from datetime import datetime, timedelta


# set up simple logging
logging.getLogger().setLevel(os.environ['LOGGING_LEVEL'])

# Set Variables
region = os.environ.get('REGION')
sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
event = {
    "source": "aws.cloudwatch",
    "alarmArn": "arn:aws:cloudwatch:us-east-1:567243246807:alarm:phil-global-auth-failure",
    "accountId": "567243246807",
    "time": "2024-10-26T19:00:38.856+0000",
    "region": "us-east-1",
    "alarmData": {
        "alarmName": "phil-global-auth-failure", 
        "state": {
            "value": "ALARM",
            "reason": "Threshold Crossed: 1 datapoint [3.0 (26/10/24 18:59:00)] was greater than or equal to the threshold (1.0).",
            "reasonData": {
                "version":"1.0",
                "queryDate":"2024-10-26T19:00:38.853+0000",
                "startDate":"2024-10-26T18:59:00.000+0000",
                "statistic":"Sum",
                "period":60,
                "recentDatapoints":[3.0],
                "threshold":1.0,
                "evaluatedDatapoints":[{
                    "timestamp":"2024-10-26T18:59:00.000+0000",
                    "sampleCount":3.0,
                    "value":3.0
                }]
            },
            "timestamp": "2024-10-26T19:00:38.856+0000"
        },
        "previousState": {
            "value": "INSUFFICIENT_DATA",
            "reason": "Insufficient Data: 1 datapoint was unknown.",
            "reasonData": {
                "version":"1.0",
                "queryDate":"2024-10-26T18:38:52.499+0000",
                "statistic":"Sum",
                "period":60,
                "recentDatapoints":[],
                "threshold":1.0,
                "evaluatedDatapoints":[{
                    "timestamp":"2024-10-26T18:37:00.000+0000"
                }]
            },
            "timestamp": "2024-10-26T18:38:52.500+0000"
        },
        "configuration": {
            "description": "Alarms when an unauthorized API call is made.",
            "metrics": [{
                "id": "42c96518-5d5f-8e63-f5b4-bd61bb8e8020",
                "metricStat": {
                    "metric": {
                        "namespace": "phil-global-cloudtrail-metrics",
                        "name": "phil-global-auth-failure-counter",
                        "dimensions": {}
                    },
                    "period": 60,
                    "stat": "Sum"
                },
                "returnData": "True"
            }]
        }
    }
}

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
ATTENTION,

AWS ALARM TRIGGERD

ALARM NAME:        {}
ALARM_TIME:        {}
ALARM_DESCRIPTION: {}
ALARM_URL:         {}



(end of message)
""".format(name, time, description, url)

    try:
        sns_response = sns.publish(
            TopicArn=sns_topic_arn,
            Message=message,
            Subject="AWS ALARM - " + name,
            MessageStructure="string"
        )
        logging.info(" Publishing email to SNS Topic ARN: %s\n%s", 
            sns_topic_arn, sns_response
        )
    except botocore.exceptions.ClientError as error:
        logging.error(
            " Cannot publish to SNS Topic ARN: %s\n%s", sns_topic_arn,
                error.sns_response['Error']['Message']
        )


def lambda_handler(event, context):
    """When triggered, the lambda handler send an an Email Alert"""
    print("#"*25)
    alarm_name = event['alarmData']['alarmName']
    alarm_time = format_time(event['time'])
    alarm_description = event['alarmData']['configuration']['description']
    alarm_url = "https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:alarm/" + alarm_name
    print("alarm_name:        ", alarm_name)
    print("alarm_time:        ", alarm_time)
    print("alarm_description: ", alarm_description)
    print("alarm_url:         ", alarm_url)
    send_email_alert(alarm_name, alarm_time, alarm_description, alarm_url)
    print("#"*25)
    print("DONE")

lambda_handler(event, "context")
