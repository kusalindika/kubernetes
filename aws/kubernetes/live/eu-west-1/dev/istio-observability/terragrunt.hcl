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
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "istio" {
  config_path = "../istio"

  mock_outputs = {
    istio_namespace = "istio-system"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "../../../../modules/istio-observability"
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

    provider "kubernetes" {
      host                   = "${dependency.cluster.outputs.cluster_endpoint}"
      cluster_ca_certificate = base64decode("${dependency.cluster.outputs.cluster_certificate_authority_data}")
      exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args        = ["eks", "get-token", "--cluster-name", "${dependency.cluster.outputs.cluster_name}", "--region", "eu-west-1"]
      }
    }
  EOF
}

inputs = {
  namespace = dependency.istio.outputs.istio_namespace

  prometheus_version         = "27.5.0"
  prometheus_retention       = "6h"
  prometheus_storage_enabled = false

  kiali_version       = "2.7.0"
  kiali_auth_strategy = "anonymous"
}
