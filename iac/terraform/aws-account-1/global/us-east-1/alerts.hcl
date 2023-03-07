locals {
  topic_name                         = "alerts"
  emails                             = ["gladman_phillip@bah.com"]
  trail_name                         = "alerts-trail"
  team_list                          = "($.userIdentity.userName != \"phil\") && ($.userIdentity.userName != \"phil-bah\") && ($.userIdentity.userName != \"lexi\") && ($.userIdentity.userName != \"ses-smtp-user.20221208-121803\")"
  development_bastion_log_group_name = "/aws/ec2/phil-dev/bastion"
  production_bastion_log_group_name  = "/aws/ec2/phil-prod/bastion"
}
