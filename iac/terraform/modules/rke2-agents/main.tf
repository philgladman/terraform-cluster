locals {
  uname             = lower(var.resource_name)
}

resource "aws_security_group" "agent_sg" {
  name        = "${local.uname}-agent-sg"
  description = "Agents security group"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow all from bastion"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups  = ["${var.bastion_security_group_id}"]
  }

  ingress {
    description      = "Allow access from controlplane"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups  = ["${var.controlplane_security_group_id}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group_rule" "allow_agent_to_cp" {
  description              = "allow Agents access to the Controlplane"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.agent_sg.id
  security_group_id        = "${var.controlplane_security_group_id}"
}

#
## Create 1 agent without ASG
#

/* resource "aws_instance" "agent_instance" {
  ami                    = var.source_ami
  instance_type          = var.instance_type
  key_name               = var.master_ssh_key_name
  monitoring             = true
  vpc_security_group_ids = ["${aws_security_group.agent_sg.id}"] 
  subnet_id              = var.rke2_subnet_ids
  iam_instance_profile   = aws_iam_instance_profile.agent-profile-role.name
  user_data              = data.cloudinit_config.this.rendered
  tags                   = merge({
    "Name" = "${local.uname}-agent",
  }, var.tags)

  root_block_device {
    volume_size = 20
    encrypted   = true
    kms_key_id   = var.ebs_kms_key_arn
  }
} */

#
## Create agent with ASG
#

/* module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.5.3"

  # Autoscaling group
  name                        = "${local.uname}-agent-asg"
  min_size                    = 3
  max_size                    = 5
  desired_capacity            = 3
  wait_for_capacity_timeout   = 0
  health_check_type           = "EC2"
  vpc_zone_identifier         = var.rke2_subnet_ids

  # Launch template
  launch_template_name        = "${local.uname}-agent-lt"
  launch_template_description = "Launch template for agents"
  update_default_version      = true

  image_id                    = var.source_ami
  instance_type               = var.instance_type
  key_name                    = var.master_ssh_key_name
  enable_monitoring           = true
  iam_instance_profile_name   = aws_iam_instance_profile.agent-profile-role.name
  user_data                   = data.cloudinit_config.this.rendered

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/sda1"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        kms_key_id            = var.ebs_kms_key_arn
      }
    }
  ]

  tags = merge({
    "Name" = "${local.uname}-agent",
  }, var.tags)
} */

############## Trying without modules

/* 
resource "aws_launch_template" "agent_lt" {
  name                   = "${local.uname}-agnet-lt"
  image_id               = var.source_ami
  instance_type          = var.instance_type
  key_name               = var.master_ssh_key_name
  vpc_security_group_ids = ["${aws_security_group.agent_sg.id}"]
  user_data              = data.cloudinit_config.this.rendered
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
      encrypted   = true
      kms_key_id   = var.ebs_kms_key_arn
    }
  }

  iam_instance_profile {
    arn = "${aws_iam_instance_profile.agent-profile-role.arn}"
  }

  tags = merge({
    "Name" = "${local.uname}-agent",
  }, var.tags)
}

resource "aws_autoscaling_group" "agent" {
  name                 = "${local.uname}-agent-asg"
  vpc_zone_identifier  = var.rke2_subnet_ids

  min_size             = 3
  max_size             = 5
  desired_capacity     = 3

  health_check_type           = "EC2"
  wait_for_capacity_timeout   = var.wait_for_capacity_timeout

  dynamic "launch_template" {
    for_each = var.spot ? [] : ["spot"]

    content {
      id      = aws_launch_template.agent_lt.id
      version = "$Latest"
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.spot ? ["spot"] : []

    content {
      instances_distribution {
        on_demand_base_capacity                  = 0
        on_demand_percentage_above_base_capacity = 0
      }

      launch_template {
        launch_template_specification {
          launch_template_id   = aws_launch_template.agent_lt.id
          launch_template_name = aws_launch_template.agent_lt.name
          version              = "$Latest"
        }
      }
    }
  }

  dynamic "tag" {
    for_each = merge({
      "Name" = "${local.uname}-agent"
    }, var.tags)

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
} */

############# trail #2

resource "aws_launch_template" "agent_lt" {
  name                   = "${local.uname}-agent-lt"
  image_id               = var.source_ami
  instance_type          = var.agent_instance_type
  vpc_security_group_ids = ["${aws_security_group.agent_sg.id}"]
  key_name               = var.master_ssh_key_name
  update_default_version = true
  user_data              = data.cloudinit_config.this.rendered
  iam_instance_profile {
    name = aws_iam_instance_profile.agent-profile-role.name
  }
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
      encrypted   = true
      kms_key_id  = var.ebs_kms_key_arn
    }
  }
}

resource "aws_autoscaling_group" "agent_asg" {
  name                      = "${local.uname}-agent-asg"
  vpc_zone_identifier       = var.rke2_subnet_ids
  health_check_type         = "EC2"
  desired_capacity          = 3
  max_size                  = 5
  min_size                  = 3
  wait_for_capacity_timeout = 0

  launch_template {
    id      = aws_launch_template.agent_lt.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge({
      "Name" = "${local.uname}-agent"
    }, var.tags)
    
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

####### TEST
/* resource "aws_launch_template" "test_lt" {
  name                   = "${local.uname}-test-lt"
  image_id               = var.source_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.agent_sg.id}"]
  key_name               = var.master_ssh_key_name
  update_default_version = true
  iam_instance_profile {
    name = aws_iam_instance_profile.test-profile-role.name
  }
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
      encrypted   = true
      kms_key_id  = var.ebs_kms_key_arn
      #kms_key_id  = "arn:aws:kms:us-east-1:567243246807:key/6f7218de-1d68-4543-9503-53bafae6decc"
    }
  }
}

resource "aws_autoscaling_group" "test_asg" {
  name                 = "${local.uname}-test-asg"
  vpc_zone_identifier  = var.rke2_subnet_ids
  health_check_type    = "EC2"
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  wait_for_capacity_timeout = 0

  launch_template {
    id      = aws_launch_template.test_lt.id
    version = "$Latest"
  }
} */

##### Creating and attaching IAM roles and policies

resource "aws_iam_role_policy_attachment" "s3-attachment" {
    role       = aws_iam_role.agent-role.name
    policy_arn = aws_iam_policy.agent-s3-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "kms-attachment" {
    role       = aws_iam_role.agent-role.name
    policy_arn = aws_iam_policy.agent-kms-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm-attachment" {
    role       = aws_iam_role.agent-role.name
    policy_arn = aws_iam_policy.agent-ssm-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch-attachment" {
    role       = aws_iam_role.agent-role.name
    policy_arn = aws_iam_policy.agent-cloudwatch-agent-access-policy.arn
}

resource "aws_iam_policy" "agent-s3-access-policy" {
  name        = "${local.uname}-agent-s3-access-policy"
  path        = "/"
  description = "S3 policy"
  policy      = data.aws_iam_policy_document.s3_access_policy_doc.json
}

resource "aws_iam_policy" "agent-kms-access-policy" {
  name        = "${local.uname}-agent-kms-access-policy"
  path        = "/"
  description = "KMS policy"
  policy      = data.aws_iam_policy_document.kms_access_policy_doc.json
} 

resource "aws_iam_policy" "agent-ssm-access-policy" {
  name        = "${local.uname}-agent-ssm-access-policy"
  path        = "/"
  description = "SSM policy"
  policy      = data.aws_iam_policy_document.ssm_access_policy_doc.json
} 

resource "aws_iam_policy" "agent-cloudwatch-agent-access-policy" {
  name        = "${local.uname}-agent-cloudwatch-agent-policy"
  path        = "/"
  description = "Cloudwatch Agent policy"
  policy      = data.aws_iam_policy_document.cloudwatch_agent_policy_doc.json
} 

resource "aws_iam_role" "agent-role" {
  name               = "${local.uname}-agent-role"
  assume_role_policy = data.aws_iam_policy_document.assume-agent-role.json
  tags               = var.tags
}

resource "aws_iam_instance_profile" "agent-profile-role" {
  name = "${local.uname}-agent-profile-role"
  role = aws_iam_role.agent-role.name
}
