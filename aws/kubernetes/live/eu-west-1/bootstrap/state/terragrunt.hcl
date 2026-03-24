terraform {
  source = "../../../../modules/state-s3"
}

generate "bootstrap_backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    terraform {
      backend "local" {}
    }
  EOF
}

generate "providers_bootstrap" {
  path      = "providers.generated.tf"
  if_exists = "overwrite"
  contents  = <<-EOF

    provider "aws" {
      region = "eu-west-1"
      default_tags {
        tags = {
          managedBy = "terragrunt"
          project   = "k8s-project"
          stack     = "bootstrap"
        }
      }
    }
  EOF
}

inputs = {
  aws_region   = "eu-west-1"
  environment  = "bootstrap"
}
