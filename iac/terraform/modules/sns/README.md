# SNS Module

Description: This module contains the configuration to create an SNS Topic, as well as subcribes email(s) to the topic

# Steps to create topic and subscriptions
- To create a SNS Topic, first edit the `iac/terraform/clusters/<environment>/il2/us-east-1/sns.hcl` with the following;
    - add in the name to call this topic.
    - add in the email address(s) you want to subscribe to this topic.
    - add in the kms-key-id that will be used for encryption.
- cd into the applicable environment. (Ex. `cd iac/terraform/cluster/sandbox`)
- Run `terragrunt run-all apply --terragrunt-working-dir il2/us-east-1/sns`
- This will create a SNS Topic and subscribe each email to the Topic.
- This will then send a email, to each email address, with a link to click to officially subscribe to the topic, you must click this link in order to receive any emails.

# How to manually publish a test message 
## Via AWS Console
- Login to the AWS console
- Go to the SNS console
- Click on `Topics`
- Click on your topics name
- Click `Publish Message`
- Fill out the `Subject`
- Fill out the `Message Body`
- Scroll down and click `Publish Message`

## Via AWS CLI
- run `aws sns list-topics --profile <profile-name>` and copy the `TopicArn` of your topic
- run `aws sns publish --topic-arn <your-topic-arn> --subject "test" --message "This is a test message" --profile <profile-name>`
- Check email for test message