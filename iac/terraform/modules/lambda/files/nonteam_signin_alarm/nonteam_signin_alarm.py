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
authorized_team_list = os.environ.get('AUTHORIZED_TEAM_LIST')

def get_recent_login_events():
    """Query Cloudtrail, and get a list of recent AWS Console Login events"""
    cloudtrail = boto3.client('cloudtrail', region_name=region)
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(minutes=10)
    recent_login_events = cloudtrail.lookup_events(
        LookupAttributes=[
            {
                'AttributeKey': 'EventName',
                'AttributeValue': 'ConsoleLogin'
            },
        ],
        StartTime=start_time,
        EndTime=end_time,
        MaxResults=10,
    )

    return recent_login_events

def get_authorized_team_list():
    """Creates a list of usernames from an unformatted list"""
    num_of_team_members = authorized_team_list.count('principalId')
    team_list = []
    for i in range(num_of_team_members):
        username = ((authorized_team_list.split('principalId')[i+1]).split('"')[1]).split(':')[1]
        team_list.append(username)

    return team_list

def format_time(cloudtrail_event):
    """Inputs the time received from AWS and reformats & converts to CST time. The newly formatted time will look like this, 14:34:18 CST on Aug 04, 2023"""
    event_time = (cloudtrail_event.split('"')[25])
    unformatted_time = datetime.strptime(event_time,'%Y-%m-%dT%H:%M:%S%z')
    unformatted_central_time = unformatted_time - timedelta(hours=5)
    formatted_central_time = datetime.strftime(unformatted_central_time,'%H:%M:%S CST on %b %d, %Y')

    return formatted_central_time

def send_email_alert(username, time):
    """Publish an alerting email message to the SNS Topic"""
    sns = boto3.client('sns', region_name=region)
    message="""
ATTENTION,

NON team member {} signed into AWS Account at {}.



(end of message)
""".format(username,time)

    try:
        sns_response = sns.publish(
            TopicArn=sns_topic_arn,
            Message=message,
            Subject='non-team-signin',
            MessageStructure='string'
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
    """When triggerd, this will send an email alert message containing the USERNAME and TIME of when the unauthorized user signed in"""
    recent_login_events = get_recent_login_events()
    team_list = get_authorized_team_list()
    for login_event in recent_login_events['Events']:
        username = login_event['Username']
        time = format_time(login_event['CloudTrailEvent'])
        if username not in team_list:
            send_email_alert(username, time)
