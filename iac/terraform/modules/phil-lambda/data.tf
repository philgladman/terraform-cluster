data "archive_file" "k8s_deploy_zipped" {
type        = "zip"
source_dir  = "${path.module}/k8s_deploy"
output_path = "${path.module}/k8s_deploy.zip"
}