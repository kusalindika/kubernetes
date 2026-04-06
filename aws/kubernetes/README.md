# EKS/Karpenter Phase 0-4 IaC

This directory contains a Terraform + Terragrunt implementation for:

- Phase 0: minimal Terraform state bootstrap (S3 only)
- Phase 1: per-environment networking (VPC + shared single NAT Gateway)
- Phase 2: EKS cluster baseline (production-ready, public endpoint with restricted CIDRs)
- Phase 3: Karpenter autoscaler (IRSA, SQS interruption handling, NodePools)
- Phase 4 (dev): Argo CD GitOps bootstrap + test-app deployment via Argo CD Application

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
  - Karpenter subnet discovery tags (`karpenter.sh/discovery`) on private subnets
- EKS module:
  - EKS cluster (Kubernetes 1.35) with public + private endpoint access
  - KMS CMK for secrets encryption (with key rotation)
  - OIDC provider for IRSA (workload identity)
  - Access entries (API mode) for cluster admin — no aws-auth ConfigMap
  - System managed node group (tainted `CriticalAddonsOnly` for system pods)
  - Managed add-ons: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver
  - Control-plane logging (api, authenticator for dev/stage; all types for prod)
  - SSM agent on nodes for Session Manager access
  - Karpenter discovery tag on EKS-managed primary security group
  - EKS access entry (EC2_LINUX) for Karpenter-launched nodes
- Cluster stacks for:
  - `dev` (t3.medium, desired=2, min=1, max=3)
  - `stage` (t3.medium, desired=2, min=1, max=3)
  - `prod` (t3.medium, desired=2, min=2, max=4, all log types enabled)
- Karpenter module:
  - IRSA role with 5 least-privilege IAM policies (node lifecycle, IAM integration, EKS integration, interruption, resource discovery)
  - SQS interruption queue with EventBridge rules (spot interruption, rebalance, state change, health events, capacity reservation)
  - Helm release (v1.10.0) installed in kube-system with CriticalAddonsOnly toleration
  - EC2NodeClass (AL2023, auto-discovers subnets/SGs via `karpenter.sh/discovery` tag)
  - NodePool: `general-ondemand` (c/m/r families, consolidation enabled)
  - NodePool: `general-spot` (c/m/r families, higher weight for cost optimization)
- Karpenter stacks for:
  - `dev` (cpu limit 100 on-demand + 100 spot, consolidate after 1m)
  - `stage` (cpu limit 100 on-demand + 100 spot, consolidate after 1m)
  - `prod` (cpu limit 200 on-demand + 200 spot, consolidate after 5m)
- Argo CD module:
  - Helm release for Argo CD in `argocd` namespace
  - CriticalAddonsOnly tolerations on Argo CD control-plane components
  - Optional Argo CD Application bootstrap for `test-app`
  - Optional Istio `Gateway` + `VirtualService` to expose Argo CD UI
- Argo CD stack for:
  - `dev` (tracks `main`, syncs `aws/kubernetes/apps/test-app`, exposes Argo CD via Istio host)

## Runtime account discovery

This implementation avoids hardcoding account IDs by resolving identity at runtime via:

- Terragrunt built-in: `get_aws_account_id()`
- Terraform data source: `data.aws_caller_identity.current`

## Prerequisites

- Terraform `>= 1.8.0, < 2.0.0`
- Terragrunt (current stable)
- Helm CLI (for OCI registry access)
- AWS credentials/profile with permissions for S3, EC2/VPC, VPC endpoints, EKS, IAM, KMS, SQS, EventBridge
- Region: `eu-west-1`
- EC2 Spot service-linked role (run once): `aws iam create-service-linked-role --aws-service-name spot.amazonaws.com || true`

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

5. Plan/apply Karpenter per environment (requires cluster to be applied first):

```bash
cd aws/kubernetes/live/eu-west-1/dev/karpenter
terragrunt init
terragrunt plan
terragrunt apply
```

Repeat for:

- `aws/kubernetes/live/eu-west-1/stage/karpenter`
- `aws/kubernetes/live/eu-west-1/prod/karpenter`

6. Plan/apply Argo CD in dev (requires cluster to be applied first):

```bash
cd aws/kubernetes/live/eu-west-1/dev/argocd
terragrunt init
terragrunt plan
terragrunt apply
```

7. Run full stack plan across an environment:

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

## Key outputs (karpenter)

- `karpenter_role_arn`
- `karpenter_queue_name` / `karpenter_queue_arn`

These outputs are consumed by later phases (add-ons, observability, GitOps).

## GitOps application manifests

Argo CD tracks app manifests from this repository:

- `aws/kubernetes/apps/test-app/namespace.yaml`
- `aws/kubernetes/apps/test-app/deployment.yaml`
- `aws/kubernetes/apps/test-app/service.yaml`
- `aws/kubernetes/apps/test-app/kustomization.yaml`

The `dev/argocd` stack bootstraps an Argo CD `Application` named `test-app` that points to:

- Repository: `https://github.com/kusalindika/kubernetes.git`
- Revision: `main`
- Path: `aws/kubernetes/apps/test-app`

Argo CD UI exposure via Istio is enabled in `dev/argocd`:

- `enable_istio_ingress = true`
- `enable_istio_sidecar_injection = true` (labels `argocd` namespace with `istio-injection=enabled`)
- `argocd_hostname = "*"` (shared host routing)
- `argocd_base_path = "/argocd"` (Argo CD served on URI path)

With this setup, access Argo CD using:

- `http://<your-ingress-host>/argocd`

## Design tradeoffs

### Single NAT Gateway

Using one NAT Gateway for all AZs reduces cost but introduces a single point of failure for private egress. Recommended production follow-up: NAT Gateways per AZ.

### Public cluster endpoint

The cluster API endpoint is public with restricted CIDRs (`public_access_cidrs`). Currently defaults to `0.0.0.0/0` — replace with your specific IPs/CIDRs before production use. Private endpoint access is also enabled, so in-VPC traffic stays internal.

### System node group taint

The system node group has a `CriticalAddonsOnly=true:NoSchedule` taint. Only system pods with matching tolerations will be scheduled there. Workload pods require Karpenter or additional node groups.

### Karpenter spot NodePool

The `general-spot` NodePool has a higher weight (100) than `general-ondemand` (50), so Karpenter prefers spot capacity for cost optimization. If spot is unavailable, it falls back to on-demand. Disable the spot pool per-environment with `enable_spot_pool = false`.

### Karpenter consolidation

Consolidation is set to `WhenEmptyOrUnderutilized` -- Karpenter will terminate and replace nodes to reduce costs. Prod uses a 5-minute cooldown (`consolidate_after = "5m"`) to avoid churn during transient load changes.

## Validation (Karpenter)

After applying the Karpenter stack, verify it's working:

```bash
kubectl get nodepools
kubectl get ec2nodeclasses
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter -c controller --tail=50
```

Scale test:

```bash
kubectl create deployment inflate --image=public.ecr.aws/eks-distro/kubernetes/pause:3.7 --requests.cpu=1 --replicas=5
kubectl get nodes -w
kubectl delete deployment inflate
```

## Validation (Argo CD + test-app)

After applying the Argo CD stack in dev, verify:

```bash
kubectl -n argocd get pods
kubectl -n argocd get applications.argoproj.io
kubectl -n test-app get deploy,svc,pods
kubectl -n argocd get gateway,virtualservice
```
