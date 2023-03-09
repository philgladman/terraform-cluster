# Alerts Module
This terraform module creates all the AWS Resources needed to enable Cloudwatch Alarms and send emails when Alarms are triggered. This includes creating a Cloudtrail Trail, S3 bucket for Cloudtrail, Cloudwatch Log Group, Cloudwatch Metric Filters and Alarms, and an SNS topic, and subscribes the teams emails to the SNS Topic. 

The Cloudtrail Trail allows the AWS logs to be stored in an S3 bucket, as well as to be pushed to a Cloudwatch Log Group for monitoring. Once the logs are in a Log Group in Cloudwatch, an Alarm will get triggered if any data inside the logs matches the Metric Filter & Alarm. If an Alarm gets triggered, the Cloudwatch Alarm will trigger the SNS Topic, and then the SNS Topic will send and emailed alert to all emails that are subscribed to that email.

## Flow
Example when an unauthorized user logs into our AWS Account.

```
---> Unauthorized User logs into TCODE AWS Console
    ---> Login event gets recorded in CloudTrail Trail
        ---> Cloudtrail Trail pushes Logs to Cloudwatch Log Group, as well as saves logs in S3 Bucket.
            ---> Login event in Cloudwatch Log Group matches Cloudwatch Metric Filter and Alarm
                ---> Cloudwatch Alarm Gets Triggered
                    ---> Cloudwatch Alarm Triggers SNS topic
                        ---> SNS Topic sends email to all subscribed emails
```


## List of Atypical/Malicious usage for Alarms
__CMK (Customer Managed Keys) Changes__
- There should be minimal to no changes to the KMS Keys and their KMS Policies. If there are changes, this would indicate suspicious traffic.

__IAM User/Group/AccessKeys Changes__
- There are no IAM Users/Groups/AccessKeys in the TCODE AWS Account, nor will these ever be created. So if these ever do get created, this would indicate suspicious traffic.

__AWS Root user usage__
- The TCODE Team does not have access to the AWS ROOT Users access keys or password. It is also AWS Best practice to never use the AWS Root User account. If the AWS Root User account is used, this would indicate suspicious traffic.

__AWS Console Sign in Failure__
- Since the TCODE AWS Account does not have any IAM Users, there shouldn't be any users trying to sign into the TCODE AWS Account. If someone tries to sign into the TCODE AWS Account with an IAM User, the sign in will fail, and this would indicate suspicious traffic. 

__NON TCODE Team AWS Console Login__
- The only members who should have access to sign into the TCODE AWS Account is the TCODE Team. If someone signs into the TCODE AWS Account who is not on the approved `team_list`, this would indicate suspicious traffic.

__Failed SSH logins to Bastions__
- Failed SSH Login attempts to one of the Bastions could indicate malicious behavior as an unauthorized user may be trying to gain access to the TCODE Environment

__Exceeded Failed SSH login attempts to Bastions__
- Exceeded the max number of failed SSH attempts to one of the Bastions could indicate malicious behavior as an unauthorized user may be trying to gain access to the TCODE Environment

__Delete RDS Database__
- There should no deletions of a RDS Database unless purposely done by the TCODE Team. If someone is deleting a RDS Database, this would indicate suspicious traffic.

__Delete S3 Bucket__
- There should no deletions of a S3 Buckets unless purposely done by the TCODE Team. If someone is deleting a S3 Buckets, this would indicate suspicious traffic.

__Delete SSM Parameter__
- There should no deletions of a SSM Parameter unless purposely done by the TCODE Team. If someone is deleting a SSM Parameter, this would indicate suspicious traffic.

__Delete Secret in Secrets Manager__
- There should no deletions of a Secret in the Secrets Manager unless purposely done by the TCODE Team. If someone is deleting a Secret in the Secrets Manager, this would indicate suspicious traffic.

__VPC Changes__
- C1 handles all VPC Changes. There should be no additional changes to the VPCs unless purposely done by the C1/TCODE Team. If someone is making changes to a VPC, this would indicate suspicious traffic.

__Subnet Changes__
- C1 handles all Subnet Changes. There should be no additional changes to the Subnets unless purposely done by the C1/TCODE Team. If someone is making changes to a Subnet, this would indicate suspicious traffic.

__Security Group Changes__
- There should be no additional changes to the Security Groups unless purposely done by the TCODE Team. If someone is making changes to a Security Group, this would indicate suspicious traffic.

__NACL Changes__
- There should be no additional changes to the NACLs unless purposely done by the TCODE Team. If someone is making changes to a NACL, this would indicate suspicious traffic.

__EC2 Large instance creation__
- As of now, the largest EC2 Instance TCODE uses *.2xlarge. If an EC2 Instance is spun up that is bigger than a *.2xlarge, such as a *.4xlarge or *.8xlarge, this would indicate suspicious traffic.

