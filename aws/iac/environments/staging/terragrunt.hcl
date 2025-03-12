terraform {
  source = "../../modules/vpc"
}

terraform {
  source = "../../modules/igw"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  vpc_cidr     = "10.16.0.0/16"
  env          = "staging"
  project_name = "personal"
  vpc_id = modules.vpc.id
}