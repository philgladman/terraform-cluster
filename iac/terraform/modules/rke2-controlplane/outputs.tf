output "controlplane_security_group_id" {
  value = aws_security_group.controlplane_sg.id
}

output "controlplane_private_ip" {
  value = aws_instance.controlplane_instance.private_ip
}

output "token_bucket_id" {
  value = aws_s3_bucket.cluster_bucket.id
}

output "token_bucket_arn" {
  value = aws_s3_bucket.cluster_bucket.arn
}

output "token_object_id" {
  value = aws_s3_object.cluster_token.id
}
