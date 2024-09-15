terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.66.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}