include "root" {
  path = "${get_terragrunt_dir()}/../../../../terragrunt.hcl"
}

locals {
  env_cfg = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "cluster" {
  config_path = "../cluster"

  mock_outputs = {
    cluster_name                       = "mock-eks"
    cluster_endpoint                   = "https://mock"
    cluster_certificate_authority_data = "bW9jaw=="
    oidc_provider_arn                  = "arn:aws:iam::123456789012:oidc-provider/mock"
    oidc_provider_url                  = "oidc.eks.eu-west-1.amazonaws.com/id/MOCK"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "networking" {
  config_path = "../networking"

  mock_outputs = {
    vpc_id = "vpc-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "../../../../modules/aws-lb-controller"
}

generate "k8s_providers" {
  path      = "k8s-providers.generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "helm" {
      kubernetes {
        host                   = "${dependency.cluster.outputs.cluster_endpoint}"
        cluster_ca_certificate = base64decode("${dependency.cluster.outputs.cluster_certificate_authority_data}")
        exec {
          api_version = "client.authentication.k8s.io/v1beta1"
          command     = "aws"
          args        = ["eks", "get-token", "--cluster-name", "${dependency.cluster.outputs.cluster_name}", "--region", "eu-west-1"]
        }
      }
    }
  EOF
}

inputs = {
  cluster_name      = dependency.cluster.outputs.cluster_name
  environment       = local.env_cfg.locals.environment
  oidc_provider_arn = dependency.cluster.outputs.oidc_provider_arn
  oidc_provider_url = dependency.cluster.outputs.oidc_provider_url
  vpc_id            = dependency.networking.outputs.vpc_id

  aws_lb_controller_version  = "1.12.0"
  aws_lb_controller_replicas = 1
}
