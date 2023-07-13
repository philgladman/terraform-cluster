# terraform-cluster 
Builds an RKE2 AMI with Packer and Ansible. Provisions AWS Infrastructure with Terraform/Terragrunt.

AWS Infrastrucutre:
- VPC
- KMS keys
- Bastion EC2 Instance
- RKE2 Kubernetes Cluster with custom AMI
- Lambda Functions
- Email Alerting Stack (Cloudtrail, Coudwatch, S3, SNS)
