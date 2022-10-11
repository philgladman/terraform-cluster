source "amazon-ebs" "rhel" {
  ami_name             = "3-hardened-packer-rhel-8"
  instance_type        = "t2.micro"
  region               = "us-east-1"
  source_ami           = "ami-06640050dc3f556bb"
  ssh_keypair_name     = "packer-build-key"
  ssh_private_key_file = "~/Desktop/DevOps/packer-build-key.pem"
  vpc_id               = "vpc-05abebfb8c8622b93"
  subnet_id            = "subnet-01e29fb03f87784eb"
  ssh_username         = "ec2-user"
  tags = {
    Name           = "3-hardened-packer-rhel-8"
  }
}

build {
  sources = ["source.amazon-ebs.rhel"]

  provisioner "shell" {
    inline           = ["while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 5; done"]
  }

  provisioner "shell" {
    inline           = ["sudo lsblk"]
  }

  provisioner "ansible" {
      playbook_file    = "../ansible/rke2.yml"
      ansible_env_vars = ["ANSIBLE_REMOTE_TEMP='/tmp/.ansible/'"]
      extra_arguments  = ["-vv"]
      user             = "ec2-user"

  }

  provisioner "shell" {
    expect_disconnect = true
    inline            = ["sudo reboot"]
    inline_shebang    = "/bin/bash -e"
  }

  provisioner "shell" {
    inline       = ["uptime"]
    pause_before = "2m0s"
  }

#  provisioner "shell" {
#    inline           = ["sudo oscap xccdf eval --fetch-remote-resources --profile xccdf_org.ssgproject.content_profile_ospp --results-arf /tmp/arf.xml --report /tmp/report.html /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml && 2>/dev/null || exit 0"]
#  }
#
#  provisioner "shell" {
#    inline           = ["sudo chown ec2-user /tmp/arf.xml /tmp/report.html"]
#  }
#
#  provisioner "file" {
#    destination = "arf.xml"
#    direction   = "download"
#    source      = "/tmp/arf.xml"
#  }
#
#  provisioner "file" {
#    destination = "report.html"
#    direction   = "download"
#    source      = "/tmp/report.html"
#  }
#
#  post-processors {
#    post-processor "artifice" {
#      files = ["report.html", "arf.xml"]
#    }
#    post-processor "compress" {
#      output = "results.tar.gz"
#    }
#  }
}