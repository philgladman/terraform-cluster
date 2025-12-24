locals {
  uname = lower(var.resource_name)
  env   = "dev"
}

data "aws_region" "current" {}
data "aws_partition" "current" {}

################################################################################
# Key Pair
################################################################################

resource "tls_private_key" "example" {
  algorithm = var.private_key_algorithm
  rsa_bits  = var.private_key_rsa_bits
}

resource "aws_key_pair" "example" {
  key_name   = "${local.uname}-imagebuilder-key"
  public_key = tls_private_key.example.public_key_openssh
  tags       = var.tags
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "example" {
  name        = "${local.uname}-imagebuilder-sg"
  description = "Imagebuilder security group"
  vpc_id      = var.vpc_id

  #   ingress {
  #     description = "Allow SSH"
  #     from_port   = 22
  #     to_port     = 22
  #     protocol    = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

################################################################################
# AWS IAM Role & Instance Profile
################################################################################

data "aws_iam_policy_document" "example_trust_pol" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "example" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:List*"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:GenerateData*"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:*",
      "ec2:*",
      "ssmmessages:*",
      "imagebuilder:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "example" {
  name        = "${local.uname}-imagebuilder"
  path        = "/"
  description = "IAM Policy for EC2 Image Builder"
  policy      = data.aws_iam_policy_document.example.json
}

resource "aws_iam_role" "example" {
  name               = "${local.uname}-imagebuilder"
  assume_role_policy = data.aws_iam_policy_document.example_trust_pol.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}

# resource "aws_iam_role_policy_attachment" "attach_ssm_aws_pol" {
#   role       = aws_iam_role.example.name
#   policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

resource "aws_iam_instance_profile" "example" {
  name = "${local.uname}-imagebuilder"
  role = aws_iam_role.example.name
}

################################################################################
# Image Builder
################################################################################

resource "aws_imagebuilder_infrastructure_configuration" "example" {
  name                  = "${local.uname}-imagebuilder-iac-config"
  description           = "test"
  instance_profile_name = aws_iam_instance_profile.example.name
  instance_types        = ["t3.micro"]
  key_pair              = aws_key_pair.example.key_name
  security_group_ids    = [aws_security_group.example.id]
  #   sns_topic_arn                 = aws_sns_topic.example.arn
  subnet_id                     = var.private_subnet_id
  terminate_instance_on_failure = true

  #   logging {
  #     s3_logs {
  #       s3_bucket_name = var.logging_s3_bucket_name
  #       s3_key_prefix  = "logs"
  #     }
  #   }

  tags = var.tags
}

resource "aws_imagebuilder_image_pipeline" "example" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.example.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.example.arn
  name                             = "${local.uname}-imagebuilder-pipeline"

  # schedule {
  #   schedule_expression = "cron(0 0 * * ? *)"
  # }

  # Starting with version 5.74.0, lifecycle meta-argument replace_triggered_by must be used in order to prevent a dependency error on destroy.
  lifecycle {
    replace_triggered_by = [
      aws_imagebuilder_image_recipe.example
    ]
  }
}

resource "aws_imagebuilder_component" "example1" {
  name     = "${local.uname}-hello-world-1"
  platform = "Linux"
  version  = "1.0.0"
  data     = <<-YAML
    name: "Test-component-inline"
    description: "This is a test"
    schemaVersion: 1.0
    constants:
      - ScriptFullName:
          type: string
          value: '/tmp/test.sh'
    phases:
      - name: build
        steps:
          - name: CreatingTestFile
            action: CreateFile
            inputs:
              - path: '{{ ScriptFullName }}'
                content: |-
                  #!/bin/bash
                  set -euox pipefail

                  echo "########################################"
                  echo "example 1 - inline"
                  echo "########################################"

                  echo "hello world from '{{ ScriptFullName }}'"
                  echo "ENV: ${local.env}"

                  echo "done"
                  exit 0
                overwrite: false
                owner: "root"
                group: "root"
                permissions: "0700"
          - name: ExecuteTestScript
            action: ExecuteBash
            onFailure: Continue
            inputs:
              commands:
                - /bin/bash '{{ ScriptFullName }}'
  YAML
}

resource "aws_imagebuilder_component" "example2" {
  name     = "${local.uname}-hello-world-2"
  platform = "Linux"
  version  = "1.0.0"
  data = templatefile("${path.module}/scripts/test-raw.yaml",
    {
      ENV = local.env
  })
}

## Renders the worst in AWS Console
resource "aws_imagebuilder_component" "example3" {
  name     = "${local.uname}-hello-world-3"
  platform = "Linux"
  version  = "1.0.0"
  data = yamlencode({
    name = "Test-component-just-script"
    description = "This is a test"
    constants = [{
      ScriptFullName = {
        type = "string"
        value = "/tmp/test.sh"
      }
    }]
    phases = [{
      name = "build"
      steps = [
        {
          name   = "CreateTestFile"
          action = "CreateFile"
          inputs = [{
            overwrite   = false
            owner       = "root"
            group       = "root"
            permissions = 0700
            content        = templatefile("${path.module}/scripts/test.sh",
              {
                DATA = "example 3 - just script"
                ENV = local.env
              })
            path     = "'{{ ScriptFullName }}'"
          }]
          onFailure = "Continue"
        },
        {
          name   = "ExecuteTestScript"
          action = "ExecuteBash"
          inputs = {
            commands = ["/bin/bash /tmp/test.sh"]
          }
          onFailure = "Continue"
        }
      ]
    }]
    schemaVersion = 1.0
  })
}

resource "aws_imagebuilder_component" "example4" {
  name     = "${local.uname}-hello-world-4"
  platform = "Linux"
  version  = "1.0.0"
  data     = <<-YAML
    name: "Test-component-inline"
    description: "This is a test"
    schemaVersion: 1.0
    constants:
      - ScriptFullName:
          type: string
          value: '/tmp/test.sh'
    phases:
      - name: build
        steps:
          - name: CreatingTestFile
            action: CreateFile
            inputs:
              - path: '{{ ScriptFullName }}'
                content: |-
                  ${indent(14, templatefile(
                    "${path.module}/scripts/test.sh",
                    {
                      DATA = "example 4 - inline with templatefile on script only"
                      ENV = local.env
                    }
                  ))}
          - name: ExecuteTestScript
            action: ExecuteBash
            onFailure: Continue
            inputs:
              commands:
                - /bin/bash '{{ ScriptFullName }}'
  YAML
}
data "aws_ami" "example" {
  most_recent = true
  owners      = ["amazon"]
  region      = data.aws_region.current.region

  filter {
    name   = "architecture"
    values = ["${var.source_ami_arch}"]
  }

  filter {
    name   = "name"
    values = ["${var.ami_name_prefix}-${var.source_ami_arch}-standard-${var.eks_version}-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_imagebuilder_image_recipe" "example" {
  name         = "${local.uname}-imagebuilder-recipe"
  parent_image = data.aws_ami.example.id
  version      = "1.0.0"

  block_device_mapping {
    device_name = "/dev/xvdb"

    ebs {
      delete_on_termination = true
      volume_size           = 30
      volume_type           = "gp3"
    }
  }

  component {
    component_arn = aws_imagebuilder_component.example1.arn
  }

  component {
    component_arn = aws_imagebuilder_component.example2.arn
  }

  component {
    component_arn = aws_imagebuilder_component.example3.arn
  }

  component {
    component_arn = aws_imagebuilder_component.example4.arn
  }

  component {
    component_arn = "arn:${data.aws_partition.current.partition}:imagebuilder:${data.aws_region.current.region}:aws:component/stig-build-linux/1.0.5/1"
  }
}
