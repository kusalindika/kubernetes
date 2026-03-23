locals {
  environment = "prod"
  vpc_cidr    = "10.42.0.0/16"
  azs         = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  public_subnet_cidrs  = ["10.42.0.0/20", "10.42.16.0/20", "10.42.32.0/20"]
  private_subnet_cidrs = ["10.42.64.0/20", "10.42.80.0/20", "10.42.96.0/20"]
}
