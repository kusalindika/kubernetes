include "root" {
  path = "${get_terragrunt_dir()}/../../../../terragrunt.hcl"
}

locals {
  env_cfg = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "networking" {
  config_path = "../networking"

  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = { "eu-west-1a" = "subnet-a", "eu-west-1b" = "subnet-b", "eu-west-1c" = "subnet-c" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "../../../../modules/eks"
}

inputs = {
  name_prefix        = "k8s-${local.env_cfg.locals.environment}"
  environment        = local.env_cfg.locals.environment
  cluster_version    = "1.35"
  vpc_id             = dependency.networking.outputs.vpc_id
  private_subnet_ids = values(dependency.networking.outputs.private_subnet_ids)
  public_access_cidrs = ["0.0.0.0/0"]
  cluster_log_types  = ["api", "authenticator"]

  admin_principal_arns       = []
  system_node_instance_types = ["t3.medium"]
  system_node_desired        = 2
  system_node_min            = 1
  system_node_max            = 3
}
