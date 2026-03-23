locals {
  environment = "dev"
  vpc_cidr    = "10.40.0.0/16"
  azs         = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  public_subnet_cidrs  = ["10.40.0.0/20", "10.40.16.0/20", "10.40.32.0/20"]
  private_subnet_cidrs = ["10.40.64.0/20", "10.40.80.0/20", "10.40.96.0/20"]
}
