# steps to destroy cluster when getting this error below
`Error: Post "http://localhost/api/v1/namespaces/kube-system/configmaps": dial tcp 127.0.0.1:80: connect: connection refused`

- Go into s3 tfstate bucket, and download the tfstate file in the eks folder
- remove the `kubernetes_config_map` from the state file
- replace tfstate file in s3 bucket with udpated state file
- run steps here (https://discuss.hashicorp.com/t/s3-backend-state-lock-wont-release/21367/4) to remove the state lock from eks
- run terraform destroy.
