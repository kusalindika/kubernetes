include "root" {
  path = "${get_terragrunt_dir()}/../../../../terragrunt.hcl"
}

locals {
  env_cfg = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "cluster" {
  config_path = "../cluster"

  mock_outputs = {
    cluster_name                      = "mock-eks"
    cluster_endpoint                  = "https://mock"
    cluster_certificate_authority_data = "bW9jaw=="
    oidc_provider_arn                 = "arn:aws:iam::123456789012:oidc-provider/mock"
    oidc_provider_url                 = "oidc.eks.eu-west-1.amazonaws.com/id/MOCK"
    node_role_arn                     = "arn:aws:iam::123456789012:role/mock-node-role"
    cluster_primary_security_group_id = "sg-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "networking" {
  config_path = "../networking"

  mock_outputs = {
    private_subnet_ids = { "eu-west-1a" = "subnet-a", "eu-west-1b" = "subnet-b", "eu-west-1c" = "subnet-c" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "../../../../modules/karpenter"
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

    provider "kubectl" {
      host                   = "${dependency.cluster.outputs.cluster_endpoint}"
      cluster_ca_certificate = base64decode("${dependency.cluster.outputs.cluster_certificate_authority_data}")
      load_config_file       = false
      exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args        = ["eks", "get-token", "--cluster-name", "${dependency.cluster.outputs.cluster_name}", "--region", "eu-west-1"]
      }
    }
  EOF
}

inputs = {
  cluster_name                      = dependency.cluster.outputs.cluster_name
  cluster_endpoint                  = dependency.cluster.outputs.cluster_endpoint
  cluster_ca_data                   = dependency.cluster.outputs.cluster_certificate_authority_data
  environment                       = local.env_cfg.locals.environment
  oidc_provider_arn                 = dependency.cluster.outputs.oidc_provider_arn
  oidc_provider_url                 = dependency.cluster.outputs.oidc_provider_url
  node_role_arn                     = dependency.cluster.outputs.node_role_arn
  private_subnet_ids                = values(dependency.networking.outputs.private_subnet_ids)
  cluster_primary_security_group_id = dependency.cluster.outputs.cluster_primary_security_group_id

  karpenter_version              = "1.10.0"
  node_pool_instance_categories  = ["c", "m", "r"]
  node_pool_cpu_limit            = 100
  enable_spot_pool               = true
  node_pool_cpu_limit_spot       = 100
  consolidation_policy           = "WhenEmptyOrUnderutilized"
  consolidate_after              = "1m"
  node_expire_after              = "720h"
}
