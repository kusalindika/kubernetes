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
    cluster_security_group_id          = "sg-mock-additional"
    cluster_primary_security_group_id  = "sg-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "../../../../modules/istio"
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
  cluster_name                      = dependency.cluster.outputs.cluster_name
  environment                       = local.env_cfg.locals.environment
  cluster_security_group_id         = dependency.cluster.outputs.cluster_security_group_id
  cluster_primary_security_group_id = dependency.cluster.outputs.cluster_primary_security_group_id

  istio_version             = "1.26.0"
  enable_ingress_gateway    = true
  ingress_gateway_lb_scheme = "internal"
  enable_egress_gateway     = true
  mtls_mode                 = "STRICT"
  enable_access_log         = true
}
