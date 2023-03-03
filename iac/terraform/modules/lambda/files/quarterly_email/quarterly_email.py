import boto3
import logging
import botocore
import os

# Set Variables
region = os.environ.get('REGION')
sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
email_message="""
Good morning, 
    
This email is for the TCODE ISSM. This is your Quarterly Reminder to audit the TCODE AWS Privledged accounts. Please contact the TCODE Team Lead for any questions.

    
Thanks!
"""

# Set up connection to AWS SNS
sns = boto3.client('sns', region_name=region)


def lambda_handler(event, context):
    """When triggered, the lambda handler will email the ISSM to audit the Privledged Accounts"""
    try:
        response = sns.publish(
            TopicArn=sns_topic_arn,
            Message=email_message,
            Subject='TCODE ISSM Quarterly Reminder',
            MessageStructure='string'
        )
        print("Publishing email to SNS Topic ARN:", sns_topic_arn, "\n")
        print(response)

    except botocore.exceptions.ClientError as error:
        print("ERROR, Cannot publish to SNS Topic ARN:", sns_topic_arn)
        print(error.response['Error']['Message'])
