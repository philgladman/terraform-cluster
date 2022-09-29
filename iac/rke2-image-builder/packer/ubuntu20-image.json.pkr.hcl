source "amazon-ebs" "ubuntu" {
  ami_name             = "3-hardened-packer-ubuntu-20"
  instance_type        = "t2.micro"
  region               = "us-east-1"
  source_ami           = "ami-0149b2da6ceec4bb0"
  ssh_keypair_name     = "packer-build-key"
  ssh_private_key_file = "~/Desktop/DevOps/packer-build-key.pem"
  vpc_id               = "vpc-04037679"
  subnet_id            = "subnet-f838619e"
  ssh_username         = "ubuntu"
  tags = {
    Name           = "3-hardened-packer-ubuntu-20"
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "ansible" {
      playbook_file    = "../ansible/rke2.yml"
      ansible_env_vars = ["ANSIBLE_REMOTE_TEMP='/tmp/.ansible/'"]
      extra_arguments  = ["-vv"]
      user             = "ubuntu"

    }

  provisioner "shell" {
    inline           = ["sudo oscap xccdf eval --fetch-remote-resources --profile xccdf_org.ssgproject.content_profile_ospp --results-arf /tmp/arf.xml --report /tmp/report.html /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml && 2>/dev/null || exit 0"]
  }

  provisioner "shell" {
    inline           = ["sudo chown ubuntu /tmp/arf.xml /tmp/report.html"]
  }

  provisioner "file" {
    destination = "arf.xml"
    direction   = "download"
    source      = "/tmp/arf.xml"
  }

  provisioner "file" {
    destination = "report.html"
    direction   = "download"
    source      = "/tmp/report.html"
  }

  post-processors {
    post-processor "artifice" {
      files = ["report.html", "arf.xml"]
    }
    post-processor "compress" {
      output = "results.tar.gz"
    }
  }
}