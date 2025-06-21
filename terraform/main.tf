terraform {
  backend "s3" {
    bucket  = "terraform-states-ihar-tsykala-2025q2"
    key     = "prod/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

