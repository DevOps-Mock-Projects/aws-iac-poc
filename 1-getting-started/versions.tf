terraform {
  required_version = "~> 1.11.2"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # As a best practice, use the ~> style version constraints to pin your major and minor versions, 
      # allowing to apply patch version updates without modifying your Terraform configuration
      version = "~> 5.91.0"
    }
  }

}