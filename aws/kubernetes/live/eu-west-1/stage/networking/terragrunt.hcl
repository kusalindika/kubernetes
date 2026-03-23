include "root" {
  path = "${get_terragrunt_dir()}/../../../../terragrunt.hcl"
}

locals {
  env_cfg = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  name_prefix          = "k8s-${local.env_cfg.locals.environment}"
  environment          = local.env_cfg.locals.environment
  region               = "eu-west-1"
  vpc_cidr             = local.env_cfg.locals.vpc_cidr
  azs                  = local.env_cfg.locals.azs
  public_subnet_cidrs  = local.env_cfg.locals.public_subnet_cidrs
  private_subnet_cidrs = local.env_cfg.locals.private_subnet_cidrs
  enable_vpc_endpoints = true
}
