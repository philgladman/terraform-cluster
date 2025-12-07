locals {
  uname = lower(var.resource_name)
}

resource "aws_eip" "docker_arm_eip" {
  instance = aws_instance.docker_arm_instance.id
  vpc      = true
  tags     = var.tags
}

resource "aws_instance" "docker_arm_instance" {
  ami                    = var.docker_arm_ami
  instance_type          = var.instance_type
  key_name               = var.master_ssh_key_name
  monitoring             = true
  vpc_security_group_ids = ["${var.docker_arm_sg}"]
  subnet_id              = var.docker_arm_subnet_id
  # iam_instance_profile   = var.docker_arm_role
  user_data = data.cloudinit_config.this.rendered
  tags = merge({
    "Name" = "${local.uname}-docker-arm",
  }, var.tags)

  root_block_device {
    volume_size = 20
    encrypted   = true
    kms_key_id  = var.ebs_kms_key_arn
  }
}
