terraform {
  source = "../../../modules/vpc"
}

include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

inputs = {
  vpc_cidr     = "10.16.0.0/16"
  env          = include.env.locals.env
  project_name = include.env.locals.project_name
  private_cidrs = [
    "10.16.4.0/24", "10.16.8.0/24", "10.16.12.0/24"
  ]
  public_cidrs = [
    "10.16.32.0/24", "10.16.64.0/24", "10.16.96.0/24"
  ]
  azs = [
    "us-east-1a", "us-east-1b", "us-east-1c"
  ]
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"    = 1
    "kubernetes.io/cluster/staging-demo" = "owned"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb"             = 1
    "kubernetes.io/cluster/staging-demo" = "owned"
  }

}
