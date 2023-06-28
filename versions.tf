
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.48.0, < 5.0.0"
      configuration_aliases = [aws, aws.acm]
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }
  }
}