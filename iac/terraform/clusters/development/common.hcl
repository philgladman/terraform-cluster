locals {
  env_name         = "dev"
  developer        = get_env("REPO_USER")
  github_username  = get_env("GITHUB_USERNAME")
  github_pat       = get_env("GITHUB_PAT")
}
