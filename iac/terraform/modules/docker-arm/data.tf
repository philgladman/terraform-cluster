data "cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "00_userdata.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/userdata.sh", {
    })
  }
}

data "aws_caller_identity" "current" {}
