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
    ingress_gateway_namespace = "istio-ingress"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "../../../../modules/test-app"
}

generate "k8s_providers" {
  path      = "k8s-providers.generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "kubernetes" {
      host                   = "${dependency.cluster.outputs.cluster_endpoint}"
      cluster_ca_certificate = base64decode("${dependency.cluster.outputs.cluster_certificate_authority_data}")
      exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args        = ["eks", "get-token", "--cluster-name", "${dependency.cluster.outputs.cluster_name}", "--region", "eu-west-1"]
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
  namespace         = "test-app"
  frontend_replicas = 2
  backend_replicas  = 2
  frontend_image    = "nginx:1.27-alpine"
  backend_image     = "hashicorp/http-echo:0.2.3"
  backend_message   = "hello from backend"
  app_hostname      = "*"

  istio_ingress_gateway_namespace = dependency.istio.outputs.ingress_gateway_namespace
}
