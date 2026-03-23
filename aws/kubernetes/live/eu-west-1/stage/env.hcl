locals {
  environment = "stage"
  vpc_cidr    = "10.41.0.0/16"
  azs         = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  public_subnet_cidrs  = ["10.41.0.0/20", "10.41.16.0/20", "10.41.32.0/20"]
  private_subnet_cidrs = ["10.41.64.0/20", "10.41.80.0/20", "10.41.96.0/20"]
}
