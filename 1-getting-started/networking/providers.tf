provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  # shared_config_files      = ["~/.aws/config"]
  # shared_credentials_files = ["~/.aws/credentials"]
}
