terraform {
  source = "../../../modules/aws_load_balancer_controller"
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
  env                                       = include.env.locals.env
  eks_name                                  = dependency.eks.outputs.eks_name
  openid_provider_arn                       = dependency.eks.outputs.openid_provider_arn
  aws_load_balancer_controller_helm_version = "1.12.0"
  aws_eks_node_group                        = dependency.eks.outputs.node_groups["general"]
  vpcId                                     = dependency.vpc.outputs.vpc_id
}

dependency "vpc" {
  config_path = find_in_parent_folders("vpc/terragrunt.hcl")

  mock_outputs = {
    vpcId = "vpc-1234567890abcdef0"
  }
}

dependency "eks" {
  config_path = find_in_parent_folders("eks/terragrunt.hcl")

  mock_outputs = {
    eks_name            = "demo"
    openid_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/12345678901234567890123456789012"
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
}

generate "helm_provider" {
  path      = "helm-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

data "aws_eks_cluster" "eks" {
    name = var.eks_name
}

data "aws_eks_cluster_auth" "eks" {
    name = var.eks_name
} 

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.eks.name]
      command     = "aws"
    }
  }
}
EOF
}
