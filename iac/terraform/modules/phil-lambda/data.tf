data "archive_file" "k8s_deploy_zipped" {
type        = "zip"
source_dir  = "${path.module}/files/k8s_deploy"
output_path = "${path.module}/files/k8s_deploy.zip"
}