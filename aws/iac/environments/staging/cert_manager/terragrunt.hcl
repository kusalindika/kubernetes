terraform {
  source = "../../../modules/cert_manager"
}

inputs = {
  cert_manager_helm_version = "1.17.2"
  enable_cert_manager       = true
  nginx_ingress_controller  = dependency.ingress_controller.outputs.external_nginx_id
  eks_name                  = dependency.eks.outputs.eks_name
}

dependency "ingress_controller" {
  config_path = find_in_parent_folders("nginx_ingress_controller/terragrunt.hcl")

  mock_outputs = {
    external_nginx_id = "external-nginx"
  }
}

dependency "eks" {
  config_path = find_in_parent_folders("eks/terragrunt.hcl")

  mock_outputs = {
    eks_name            = "demo"
    openid_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/12345678901234567890123456789012"
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

# generate kubernetes provider
generate "kubernetes_provider" {
  path      = "kubernetes-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

data "aws_eks_cluster" "eks_k8s" {
    name = var.eks_name
}

data "aws_eks_cluster_auth" "eks_k8s" {
    name = var.eks_name
} 

provider "kubernetes" {
  host = data.aws_eks_cluster.eks_k8s.endpoint
  token = data.aws_eks_cluster_auth.eks_k8s.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_k8s.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.eks_k8s.name]
    command     = "aws"
  }
}
EOF
}

