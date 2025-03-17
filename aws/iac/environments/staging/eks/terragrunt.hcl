terraform {
  source = "../../../modules/eks"
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
  eks_version = "1.32"
  env         = include.env.locals.env
  eks_name    = "demo"
  subnet_ids  = dependency.vpc.outputs.private_subnet_ids

  node_groups = {
    general = {
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3a.xlarge"]
      scaling_config = {
        desired_size = 1
        max_size     = 5
        min_size     = 0
      }
    }
  }
}

dependency "vpc" {
  config_path = find_in_parent_folders("vpc/terragrunt.hcl")

  mock_outputs = {
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
  }

}
