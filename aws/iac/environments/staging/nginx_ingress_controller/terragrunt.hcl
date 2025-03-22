terraform {
  source = "../../../modules/nginx_ingress_controller"
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
  env                             = include.env.locals.env
  eks_name                        = dependency.eks.outputs.eks_name
  ingress_nginx_helm_version      = "4.12.0"
  enable_nginx_ingress_controller = true
  aws_load_balancer_controller    = dependency.aws_load_balancer_controller.outputs.aws_load_balancer_controller_role_arn
}

dependency "aws_load_balancer_controller" {
  config_path = find_in_parent_folders("aws_load_balancer_controller/terragrunt.hcl")

  mock_outputs = {
    aws_load_balancer_controller_role_arn = "arn:aws:iam::123456789012:role/aws-load-balancer-controller"
  }
}

dependency "eks" {
  config_path = find_in_parent_folders("eks/terragrunt.hcl")

  mock_outputs = {
    eks_name = "demo"
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