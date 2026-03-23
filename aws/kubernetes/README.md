# EKS/Karpenter Phase 0-1 IaC

This directory contains a fresh Terraform + Terragrunt implementation for:

- Phase 0: minimal Terraform state bootstrap (S3 only)
- Phase 1: per-environment networking (VPC + shared single NAT Gateway)

No code is reused from other repository directories.

## What is implemented

- Terragrunt root config with:
  - AWS provider generation
  - Terraform version/provider constraints
  - S3 remote state configuration
  - No DynamoDB lock table
- Bootstrap stack:
  - Creates account-aware S3 state bucket
  - Uses local backend for first-time bootstrap
- Networking stacks for:
  - `dev`
  - `stage`
  - `prod`
- VPC module:
  - 3 AZ public and private subnets
  - Single NAT Gateway in one public subnet
  - Private subnet default route in all AZs via the same NAT Gateway
  - Baseline VPC endpoints (`s3`, `ecr.api`, `ecr.dkr`, `sts`, `logs`, `ec2`)

## Runtime account discovery

This implementation avoids hardcoding account IDs by resolving identity at runtime via:

- Terragrunt built-in: `get_aws_account_id()`
- Terraform data source: `data.aws_caller_identity.current`

## Prerequisites

- Terraform `>= 1.8.0, < 2.0.0`
- Terragrunt (current stable)
- AWS credentials/profile with permissions for S3, EC2/VPC, and VPC endpoints
- Region: `eu-west-1`

## Apply order

1. Bootstrap state bucket:

```bash
cd aws/kubernetes/live/eu-west-1/bootstrap/state
terragrunt init
terragrunt apply
```

2. Plan/apply networking per environment:

```bash
cd aws/kubernetes/live/eu-west-1/dev/networking
terragrunt init
terragrunt plan
terragrunt apply
```

Repeat for:

- `aws/kubernetes/live/eu-west-1/stage/networking`
- `aws/kubernetes/live/eu-west-1/prod/networking`

3. Run all network plans in one shot (optional):

```bash
cd aws/kubernetes/live/eu-west-1
terragrunt run-all plan --terragrunt-include-dir "*/networking"
```

## Key outputs (networking)

- `vpc_id`
- `vpc_cidr_block`
- `public_subnet_ids`
- `private_subnet_ids`
- `public_route_table_id`
- `private_route_table_ids`
- `nat_gateway_id`
- `nat_gateway_public_ip`

These outputs are intended to be consumed by later EKS phases.

## Design tradeoff: single NAT Gateway

Using one NAT Gateway for all AZs reduces cost but introduces a single point of failure for private egress.

Recommended production follow-up options:

- move to managed NAT Gateways per AZ for higher availability
