locals {
  cidr      = "10.4.0.0/16"
  endpoints = ["ec2", "ec2messages", "iam", "ssm", "ssmmessages", "kms"]
  # endpoints     = [
  #   "cloudformation",
  #   "cloudtrail",
  #   "ec2",
  #   "ec2messages",
  #   "efs",
  #   "eks",
  #   "iam",
  #   "kms",
  #   "lambda",
  #   "logs",
  #   "secretsmanager",
  #   "sns",
  #   "ssm"
  #   "ssmmessages"
  # ]
}
