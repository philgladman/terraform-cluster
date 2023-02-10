locals {
  uname             = lower(var.resource_name)
}

resource "aws_security_group" "bastion_sg" {
  name        = "${local.uname}-bastion-sg"
  description = "Bastion security group"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion_instance.id
  vpc      = true
  tags     = var.tags
}

resource "aws_instance" "bastion_instance" {
  ami                    = var.bastion_ami
  instance_type          = var.instance_type
  key_name               = var.master_ssh_key_name
  monitoring             = true
  vpc_security_group_ids = ["${aws_security_group.bastion_sg.id}"] 
  subnet_id              = var.bastion_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.bastion-profile-role.name
  user_data              = data.cloudinit_config.this.rendered
  tags                   = merge({
    "Name" = "${local.uname}-bastion",
  }, var.tags)

  root_block_device {
    volume_size = 20
    encrypted   = true
    kms_key_id   = var.ebs_kms_key_arn
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

resource "aws_iam_role_policy_attachment" "kubeconfig-attachment" {
    role       = aws_iam_role.bastion-role.name
    policy_arn = aws_iam_policy.kubeconfig-access-policy.arn
}

resource "aws_iam_policy" "bastion-s3-access-policy" {
  name        = "${local.uname}-bastion-s3-access-policy"
  path        = "/"
  description = "S3 policy"
  policy      = data.aws_iam_policy_document.s3_access_policy_doc.json
}

resource "aws_iam_policy" "bastion-kms-access-policy" {
  name        = "${local.uname}-bastion-kms-access-policy"
  path        = "/"
  description = "KMS policy"
  policy      = data.aws_iam_policy_document.kms_access_policy_doc.json
} 

resource "aws_iam_policy" "bastion-ssm-access-policy" {
  name        = "${local.uname}-bastion-ssm-access-policy"
  path        = "/"
  description = "SSM policy"
  policy      = data.aws_iam_policy_document.ssm_access_policy_doc.json
} 

resource "aws_iam_policy" "kubeconfig-access-policy" {
  name        = "${local.uname}-kubeconfig-access-policy"
  path        = "/"
  description = "Kubeconfig policy"
  policy      = data.aws_iam_policy_document.kubeconfig_access_policy_doc.json
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