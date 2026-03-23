locals {
  aws_region     = "eu-west-1"
  project_name   = "k8s-phase01"
  aws_account_id = get_aws_account_id()
  state_bucket   = "tfstate-${local.project_name}-${local.aws_account_id}-${local.aws_region}"
  default_tags = {
    managedBy = "terragrunt"
    project   = local.project_name
  }
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket  = local.state_bucket
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = local.aws_region
    encrypt = true
  }
}

generate "providers" {
  path      = "providers.generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.8.0, < 2.0.0"
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 5.0"
        }
      }
    }

    provider "aws" {
      region = "${local.aws_region}"
      default_tags {
        tags = {
          managedBy = "${local.default_tags.managedBy}"
          project   = "${local.default_tags.project}"
        }
      }
    }
  EOF
}
