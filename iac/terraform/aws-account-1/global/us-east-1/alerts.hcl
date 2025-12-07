locals {
  topic_name                         = "alerts"
  emails                             = ["phillipegladman@gmail.com"]
  trail_name                         = "alerts-trail"
  team_list                          = "($.userIdentity.userName != \"phil\") && ($.userIdentity.userName != \"phil-bah\") && ($.userIdentity.userName != \"lexi\") && ($.userIdentity.userName != \"ses-smtp-user.20221208-121803\")"
  development_bastion_log_group_name = "/aws/ec2/phil-dev/bastion"
  production_bastion_log_group_name  = "/aws/ec2/phil-prod/bastion"
  lambda_function_arn                = "arn:aws:lambda:us-east-1:567243246807:function:phil-dev-cloudwatch-alarms-notification"
  lambda_function_name               = "phil-dev-cloudwatch-alarms-notification"
}
