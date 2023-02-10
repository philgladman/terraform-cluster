locals {
  uname             = lower(var.resource_name)
}

data "aws_caller_identity" "current" {}

/* resource "aws_security_group" "cluster_sg" {
  name        = "${local.uname}-eks-cluster-sg"
  description = "EKS Cluster security group"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow all from bastion"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups  = ["${var.bastion_security_group_id}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = var.tags
} */

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "${local.uname}-test-cluster"
  cluster_version = "1.24"

  cluster_endpoint_public_access  = false

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                    = var.vpc_id
  subnet_ids                = var.private_subnet_ids
  control_plane_subnet_ids  = var.private_subnet_ids
  /* cluster_security_group_id = aws_security_group.cluster_sg.id */

  # Self Managed Node Group(s)
  /* self_managed_node_group_defaults = {
    instance_type                          = "m6i.large"
    update_launch_template_default_version = true
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  } */

  /* self_managed_node_groups = {
    one = {
      name         = "mixed-1"
      max_size     = 5
      desired_size = 2

      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 10
          spot_allocation_strategy                 = "capacity-optimized"
        }

        override = [
          {
            instance_type     = "m5.large"
            weighted_capacity = "1"
          },
          {
            instance_type     = "m6i.large"
            weighted_capacity = "2"
          },
        ]
      }
    }
  } */

  # EKS Managed Node Group(s)
  /* eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  } */

    /* eks_managed_node_group_defaults = {
    ami_id            = var.ami_id
    ebs_optimized     = true
    enable_monitoring = true
    key_name          = var.key_name
    log_group_name    = var.log_group_name
    timeouts = {
      create = var.eks_timeout_create
      update = var.eks_timeout_update
      delete = var.eks_timeout_delete
    }

    block_device_mappings = {
      sda = {
        device_name = var.ebs_device_name_01
        ebs = {
          volume_size           = var.ebs_volume_size_01
          volume_type           = var.ebs_volume_type_01
          iops                  = var.ebs_iops_01
          throughput            = var.ebs_throughput_01
          encrypted             = var.ebs_encrypted
          kms_key_id            = var.ebs_kms_key_arn
          delete_on_termination = true
        }
      },
      sde = {
        device_name = var.ebs_device_name_02
        ebs = {
          volume_size           = var.ebs_volume_size_02
          volume_type           = var.ebs_volume_type_02
          iops                  = var.ebs_iops_02
          throughput            = var.ebs_throughput_02
          encrypted             = var.ebs_encrypted
          kms_key_id            = var.ebs_kms_key_arn
          delete_on_termination = true
        }
      }
    } */


  eks_managed_node_groups = {
    /* blue = {} */
    green = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }

  cluster_security_group_additional_rules = {
    ingress = {
      description                = "EKS Cluster allows 443 port to get API call"
      type                       = "ingress"
      from_port                  = 443
      to_port                    = 443
      protocol                   = "TCP"
      source_security_group_id   = var.bastion_security_group_id
      source_node_security_group = false
    }
  }
  # aws-auth configmap
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::567243246807:role/ROL-terraform-admin"
      username = "phil-bah-role"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::567243246807:role/phil-dev-bastion-role"
      username = "bastion"
      groups   = ["system:masters"]
    },  
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::567243246807:user/phil"
      username = "phil"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = [
    "${data.aws_caller_identity.current.account_id}",
  ]

  tags = var.tags
}

data "aws_eks_cluster" "default" {
  name = module.eks.cluster_name
  depends_on = [
    module.eks.eks_managed_node_groups,
  ]
}

data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_name
  depends_on = [
    module.eks.eks_managed_node_groups,
  ]
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id, "--role", var.eks_admin_role_arn]
    command     = "aws"
  }
}
