locals {
  aws_region     = "eu-west-1"
  project_name   = "k8s-project"
  aws_account_id = get_aws_account_id()
  state_bucket   = "bootstrap-${local.aws_account_id}-tfstate"
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
