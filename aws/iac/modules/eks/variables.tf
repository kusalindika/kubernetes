variable "env" {
  description = "The environment name"
  type        = string
}

variable "eks_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "eks_version" {
  description = "The version of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "The subnet ids of private"
  type        = list(string)

}

variable "node_groups" {
  description = "EKS node groups"
  type        = map(any)

}

variable "enable_irsa" {
  description = "Enable IRSA"
  type        = bool
  default     = true

}

variable "node_iam_policies" {
  description = "List of IAM Policies to attach to EKS-managed nodes."
  type        = map(any)
  default = {
    1 = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    2 = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    3 = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    4 = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}