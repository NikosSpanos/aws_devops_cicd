# Configure the Microsoft Azure Provider.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "remote" {
    organization = "codehub-spanos" #terraform cloud main user

    workspaces {
      name = "aws_devops_cicd" #terraform cloud workspace
    }
  }
}

//note: every input variable in main.tf file needs to be declared in a separate variables.tf file. Otherwise, undeclared variable error is generated in terraform plan.

provider "aws"{
    profile    = "default"
    region     = var.location //configure aws cli => https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

module "virtual_machines" {
    source = "./modules/virtual_machine"
    prefix = var.prefix
}