terraform {
  source = "../../../modules/csi_driver"
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
  enable_ebs_csi_driver_encryption = false
  eks_name                         = dependency.eks.outputs.eks_name
}

dependency "eks" {
  config_path = find_in_parent_folders("eks/terragrunt.hcl")

  mock_outputs = {
    eks_name = "demo"
  }
}