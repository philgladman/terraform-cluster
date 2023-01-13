locals {
  topic_name     = "alerts"
  emails         = ["gladman_phillip@bah.com"]
  sns_kms_key_id = "alias/aws/sns"
  trail_name      = "alerts-trail"
}
