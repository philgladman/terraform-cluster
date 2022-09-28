source "amazon-ebs" "rhel" {
  ami_name             = "hardened-packer-rhel-8"
  instance_type        = "t2.micro"
  region               = "us-east-1"
  source_ami           = "ami-06640050dc3f556bb"
  ssh_keypair_name     = "packer-build-key"
  ssh_private_key_file = "~/Desktop/DevOps/packer-build-key.pem"
  vpc_id               = "vpc-04037679"
  subnet_id            = "subnet-f838619e"
  ssh_username         = "ec2-user"
  tags = {
    Name           = "hardened-packer-rhel-8"
  }
}

build {
  sources = ["source.amazon-ebs.rhel"]

  provisioner "ansible" {
      playbook_file    = "../ansible/rhel8-stig/site.yml"
      extra_arguments  = ["-vv"]
    }
}