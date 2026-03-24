# EKS/Karpenter Phase 0-2 IaC

This directory contains a Terraform + Terragrunt implementation for:

- Phase 0: minimal Terraform state bootstrap (S3 only)
- Phase 1: per-environment networking (VPC + shared single NAT Gateway)
- Phase 2: EKS cluster baseline (production-ready, public endpoint with restricted CIDRs)

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
  - EKS subnet discovery tags (`kubernetes.io/role/elb`, `kubernetes.io/role/internal-elb`, `kubernetes.io/cluster/<name>`)
- EKS module:
  - EKS cluster (Kubernetes 1.35) with public + private endpoint access
  - KMS CMK for secrets encryption (with key rotation)
  - OIDC provider for IRSA (workload identity)
  - Access entries (API mode) for cluster admin — no aws-auth ConfigMap
  - System managed node group (tainted `CriticalAddonsOnly` for system pods)
  - Managed add-ons: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver
  - Control-plane logging (api, authenticator for dev/stage; all types for prod)
  - SSM agent on nodes for Session Manager access
- Cluster stacks for:
  - `dev` (t3.medium, desired=2, min=1, max=3)
  - `stage` (t3.medium, desired=2, min=1, max=3)
  - `prod` (t3.medium, desired=2, min=2, max=4, all log types enabled)

## Runtime account discovery

This implementation avoids hardcoding account IDs by resolving identity at runtime via:

- Terragrunt built-in: `get_aws_account_id()`
- Terraform data source: `data.aws_caller_identity.current`

## Prerequisites

- Terraform `>= 1.8.0, < 2.0.0`
- Terragrunt (current stable)
- AWS credentials/profile with permissions for S3, EC2/VPC, VPC endpoints, EKS, IAM, KMS
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

4. Plan/apply EKS cluster per environment (requires networking to be applied first):

```bash
cd aws/kubernetes/live/eu-west-1/dev/cluster
terragrunt init
terragrunt plan
terragrunt apply
```

Repeat for:

- `aws/kubernetes/live/eu-west-1/stage/cluster`
- `aws/kubernetes/live/eu-west-1/prod/cluster`

5. Run full stack plan across an environment:

```bash
cd aws/kubernetes/live/eu-west-1/dev
terragrunt run-all plan
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

## Key outputs (cluster)

- `cluster_name`
- `cluster_endpoint`
- `cluster_certificate_authority_data`
- `cluster_version`
- `oidc_provider_arn` / `oidc_provider_url`
- `cluster_role_arn` / `node_role_arn`
- `kms_key_arn`
- `cluster_security_group_id` / `cluster_primary_security_group_id`

These outputs are consumed by later phases (Karpenter, add-ons).

## Design tradeoffs

### Single NAT Gateway

Using one NAT Gateway for all AZs reduces cost but introduces a single point of failure for private egress. Recommended production follow-up: NAT Gateways per AZ.

### Public cluster endpoint

The cluster API endpoint is public with restricted CIDRs (`public_access_cidrs`). Currently defaults to `0.0.0.0/0` — replace with your specific IPs/CIDRs before production use. Private endpoint access is also enabled, so in-VPC traffic stays internal.

### System node group taint

The system node group has a `CriticalAddonsOnly=true:NoSchedule` taint. Only system pods with matching tolerations will be scheduled there. Workload pods require Karpenter (Phase 3) or additional node groups.
