# EKS/Karpenter Phase 0-4 IaC

This directory contains a Terraform + Terragrunt implementation for:

- Phase 0: minimal Terraform state bootstrap (S3 only)
- Phase 1: per-environment networking (VPC + shared single NAT Gateway)
- Phase 2: EKS cluster baseline (production-ready, public endpoint with restricted CIDRs)
- Phase 3: Karpenter autoscaler (IRSA, SQS interruption handling, NodePools)
- Phase 3.5: Istio service mesh (Istiod, ingress/egress gateways, mTLS)
- Phase 4: AWS Load Balancer Controller + ALB ingress for Istio Gateway
- Test App: two-service mesh application exercising all platform features

No code is reused from other repository directories.

## Architecture

```
Client -> ALB (L7, HTTPS/TLS termination) -> Istio Ingress Gateway pods -> Envoy sidecar -> Service
```

The AWS Load Balancer Controller watches `Ingress` resources with `ingressClassName: alb` and provisions ALBs. The Istio Ingress Gateway runs as a ClusterIP service (no NLB), and a Kubernetes Ingress resource routes ALB traffic to the gateway pods via IP-mode target groups.

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

6. Plan/apply AWS Load Balancer Controller per environment (requires cluster + networking to be applied first):

```bash
cd aws/kubernetes/live/eu-west-1/dev/aws-lb-controller
terragrunt init
terragrunt plan
terragrunt apply
```

Repeat for:

- `aws/kubernetes/live/eu-west-1/stage/aws-lb-controller`
- `aws/kubernetes/live/eu-west-1/prod/aws-lb-controller`

7. Plan/apply Istio per environment (requires cluster + aws-lb-controller to be applied first):

```bash
cd aws/kubernetes/live/eu-west-1/dev/istio
terragrunt init
terragrunt plan
terragrunt apply
```

Repeat for:

- `aws/kubernetes/live/eu-west-1/stage/istio`
- `aws/kubernetes/live/eu-west-1/prod/istio`

8. Plan/apply test application (dev only, requires istio to be applied first):

```bash
cd aws/kubernetes/live/eu-west-1/dev/test-app
terragrunt init
terragrunt plan
terragrunt apply
```

9. Run full stack plan across an environment:

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

These outputs are consumed by later phases (add-ons, observability).

## Key outputs (aws-lb-controller)

- `lb_controller_role_arn`
- `lb_controller_role_name`
- `lb_controller_chart_version`
- `lb_controller_namespace`

## Key outputs (istio)

- `istiod_version`
- `istio_namespace`
- `ingress_gateway_namespace`
- `egress_gateway_namespace`
- `alb_ingress_name`

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

### ALB vs NLB for Istio Ingress

The Istio Ingress Gateway uses an ALB (Application Load Balancer, Layer 7) instead of an NLB (Network Load Balancer, Layer 4). This gives us:

- **ACM-managed TLS certificates** with automatic renewal at the ALB
- **AWS WAF integration** for web application firewall protection
- **HTTP/2 and gRPC** native support
- **Path/host-based routing** at the ALB level (in addition to Istio VirtualService routing)

Trade-off: TLS terminates at the ALB. The connection from ALB to Istio Gateway pods is a new HTTP connection. If end-to-end mTLS from client to pod is required, switch to NLB with TCP pass-through.

### Istio Gateway Service type

The Istio Ingress Gateway runs as `ClusterIP` (not `LoadBalancer`). The ALB routes to gateway pods via IP-mode target groups. This avoids double load balancing (ALB -> NLB) and reduces cost.

## Key outputs (test-app)

- `namespace`
- `frontend_service`
- `backend_service`

## Validation (Test App)

After applying the test-app stack, verify all components:

```bash
# Pods should show 2/2 READY (app container + Istio sidecar)
kubectl get pods -n test-app

# Istio resources
kubectl get gateway,virtualservice,destinationrule,peerauthentication,authorizationpolicy,serviceentry -n test-app

# Get the ALB DNS name
ALB_DNS=$(kubectl get ingress -n istio-ingress istio-ingress-alb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test frontend (should return nginx welcome page)
curl -s http://$ALB_DNS/

# Test backend via /api route (should return "hello from backend")
curl -s http://$ALB_DNS/api

# Verify mTLS is active (STRICT)
istioctl x describe pod $(kubectl get pod -n test-app -l app=backend -o jsonpath='{.items[0].metadata.name}') -n test-app

# Verify Envoy access logs
kubectl logs -n test-app -l app=frontend -c istio-proxy --tail=10

# Verify Karpenter provisioned nodes for workload pods (no CriticalAddonsOnly taint)
kubectl get nodes -l karpenter.sh/nodepool
```

## Validation (AWS Load Balancer Controller)

After applying the aws-lb-controller stack, verify it's running:

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=20
```

## Validation (Istio + ALB)

After applying the Istio stack, verify the ALB Ingress is provisioned:

```bash
kubectl get ingress -n istio-ingress istio-ingress-alb
kubectl describe ingress -n istio-ingress istio-ingress-alb
```

The `ADDRESS` field should show the ALB DNS name. Verify the ALB is healthy:

```bash
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName,'istio')]"
```

To enable HTTPS, set `alb_certificate_arn` to an ACM certificate ARN in the Istio stack inputs. To attach AWS WAF, set `alb_waf_acl_arn`.

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
