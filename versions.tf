# Specifies required providers and their versions
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex" # Yandex Cloud provider
      version = "~> 0.130"
    }
    aws = {
      source  = "hashicorp/aws" # AWS provider (used for Terraform lock table emulation)
      version = "~> 5.44, < 5.96.0"
    }
  }
}
