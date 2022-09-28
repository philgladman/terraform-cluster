source "amazon-ebs" "ubuntu" {
  ami_name             = "2-hardened-packer-ubuntu-20"
  instance_type        = "t2.micro"
  region               = "us-east-1"
  source_ami           = "ami-0149b2da6ceec4bb0"
  ssh_keypair_name     = "packer-build-key"
  ssh_private_key_file = "~/Desktop/DevOps/packer-build-key.pem"
  vpc_id               = "vpc-04037679"
  subnet_id            = "subnet-f838619e"
  ssh_username         = "ubuntu"
  tags = {
    Name           = "2-hardened-packer-ubuntu-20"
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "ansible" {
      playbook_file    = "../ansible/rke2.yml"
      extra_arguments  = ["-vv"]
    }
}