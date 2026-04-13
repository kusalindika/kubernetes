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
  config_path  = "../istio"
  skip_outputs = true
}

terraform {
  source = "../../../../modules/argocd"
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
  cluster_name         = dependency.cluster.outputs.cluster_name
  environment          = local.env_cfg.locals.environment
  argocd_namespace     = "argocd"
  argocd_chart_version = "7.7.16"

  create_test_app_application    = true
  test_app_application_name      = "test-app"
  test_app_namespace             = "test-app"
  test_app_repo_url              = "https://github.com/kusalindika/kubernetes.git"
  test_app_target_revision       = "main"
  test_app_path                  = "aws/kubernetes/apps/test-app"
  test_app_hostname              = "*"
  test_app_create_gateway        = true
  test_app_gateway_name          = "test-app-gateway"
  test_app_gateway_namespace     = ""
  enable_istio_sidecar_injection = false

  enable_istio_ingress = true
  argocd_hostname      = "*"
  argocd_base_path     = "/argocd"
}
