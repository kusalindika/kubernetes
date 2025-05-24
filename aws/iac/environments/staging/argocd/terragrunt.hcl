terraform {
  source = "../../../modules/argocd"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  enable_argocd               = true
  argocd_helm_version         = "8.0.9"
  argocd_admin_password       = "admin"
  eks_name                    = dependency.eks.outputs.eks_name
  argocd_helm_chart_namespace = "argocd"
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
