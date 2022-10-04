locals {
  uname             = lower(var.resource_name)
}

resource "aws_security_group" "allow-ssh" {
  name        = "${local.uname}-allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion_instance.id
  vpc      = true
  tags     = var.tags
}

resource "aws_instance" "bastion_instance" {
  ami                    = "ami-06640050dc3f556bb"
  instance_type          = "t2.micro"
  key_name               = var.master_ssh_key_name
  monitoring             = true
  vpc_security_group_ids = ["${aws_security_group.allow-ssh.id}"] 
  subnet_id              = var.bastion_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.bastion-profile-role.name
  user_data              = data.cloudinit_config.this.rendered
  tags                   = merge({
    "Name" = "${local.uname}-bastion",
  }, var.tags)

  root_block_device {
    volume_size = 20
    encrypted   = true
    kms_key_id   = var.ebs_kms_key_id
  }
}

##### Creating and attaching IAM roles and policies

resource "aws_iam_role_policy_attachment" "s3-attachment" {
    role       = aws_iam_role.bastion-role.name
    policy_arn = aws_iam_policy.bastion-s3-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "kms-attachment" {
    role       = aws_iam_role.bastion-role.name
    policy_arn = aws_iam_policy.bastion-kms-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm-attachment" {
    role       = aws_iam_role.bastion-role.name
    policy_arn = aws_iam_policy.bastion-ssm-access-policy.arn
}

resource "aws_iam_policy" "bastion-s3-access-policy" {
  name        = "${local.uname}-bastion-s3-access-policy"
  path        = "/"
  description = "S3 policy"
  policy      = data.aws_iam_policy_document.bastion-s3-access-policy-doc.json
}

resource "aws_iam_policy" "bastion-kms-access-policy" {
  name        = "${local.uname}-bastion-kms-access-policy"
  path        = "/"
  description = "KMS policy"
  policy      = data.aws_iam_policy_document.bastion-kms-access-policy-doc.json
} 

resource "aws_iam_policy" "bastion-ssm-access-policy" {
  name        = "${local.uname}-bastion-ssm-access-policy"
  path        = "/"
  description = "SSM policy"
  policy      = data.aws_iam_policy_document.bastion-ssm-access-policy-doc.json
} 

data "aws_iam_policy_document" "assume-bastion-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "bastion-s3-access-policy-doc" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["s3:GetObject"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "bastion-kms-access-policy-doc" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["kms:*"]
    resources = ["${var.ebs_kms_key_arn}"]
  }
}

data "aws_iam_policy_document" "bastion-ssm-access-policy-doc" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["ssm:GetPatameter"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "bastion-role" {
  name               = "${local.uname}-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.assume-bastion-role.json
  tags               = var.tags
}

resource "aws_iam_instance_profile" "bastion-profile-role" {
  name = "${local.uname}-bastion-profile-role"
  role = aws_iam_role.bastion-role.name
}

#### EC2 Userdata

data "cloudinit_config" "this" {
  #depends_on    = [aws_eip.bastion_eip[0]]
  gzip          = true
  base64_encode = true

  part {
    filename     = "userdata.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/userdata.sh", {})
  }
}