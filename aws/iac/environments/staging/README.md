# Staging Environment Infrastructure (Terragrunt)

This directory (`/aws/iac/environments/staging`) contains the Terragrunt configuration for provisioning and managing the staging environment of your AWS EKS-based Kubernetes platform. It leverages reusable Terraform modules for a modular, maintainable, and production-ready infrastructure setup.

## Modules Used

The following modules are orchestrated via Terragrunt in this environment:

- **VPC** (`modules/vpc`):
  - Provisions the Virtual Private Cloud, subnets, routing, and networking essentials.
- **EKS** (`modules/eks`):
  - Deploys the Amazon Elastic Kubernetes Service cluster and node groups.
- **AWS Load Balancer Controller** (`modules/aws_load_balancer_controller`):
  - Installs the AWS Load Balancer Controller for managing AWS NLB/ALB resources via Kubernetes.
- **Nginx Ingress Controller** (`modules/nginx_ingress_controller`):
  - Deploys the Nginx Ingress Controller for HTTP/HTTPS routing into the cluster.
- **Cert Manager** (`modules/cert_manager`):
  - Installs cert-manager for automated certificate management within Kubernetes.
- **CSI Driver** (`modules/csi_driver`):
  - Deploys the Container Storage Interface driver for dynamic storage provisioning.
- **Kubernetes Addons** (`modules/kubernetes_addons`):
  - Installs additional Kubernetes components such as Cluster Autoscaler.
- **ArgoCD** (`modules/argocd`):
  - Deploys ArgoCD for GitOps-based continuous delivery.

## Directory Structure

- `vpc/` — VPC and networking resources
- `eks/` — EKS cluster and node group configuration
- `aws_load_balancer_controller/` — AWS Load Balancer Controller setup
- `nginx_ingress_controller/` — Nginx Ingress Controller setup
- `cert_manager/` — cert-manager deployment
- `csi_driver/` — CSI driver configuration
- `kubernetes_addons/` — Addons like Cluster Autoscaler
- `argocd/` — ArgoCD GitOps deployment

## How to Use

1. **Install Prerequisites**
   - [Terraform](https://www.terraform.io/downloads.html)
   - [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
   - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (configured with appropriate credentials)

2. **Initialize the Environment**
   ```sh
   cd aws/iac/environments/staging
   terragrunt init
   ```

3. **Plan and Apply Infrastructure**
   - To plan and apply a specific module (e.g., EKS):
     ```sh
     cd eks
     terragrunt plan
     terragrunt apply
     ```
   - To apply all modules in the correct order:
     ```sh
     terragrunt run-all plan
     terragrunt run-all apply
     ```

4. **Configuration**
   - Each module directory contains a `terragrunt.hcl` file referencing the corresponding module and passing required inputs and dependencies.
   - Shared variables and environment-specific settings are managed in `env.hcl` at the root of the staging environment.

5. **Outputs**
   - Outputs from one module (e.g., VPC ID, EKS cluster name) are passed as dependencies to others using Terragrunt's `dependency` blocks.

## Notes
- The `generate` blocks in each `terragrunt.hcl` dynamically create provider configuration files as needed.
- Sensitive values (like ArgoCD admin password) are generated and stored securely using AWS SSM Parameter Store.
- You can customize Helm chart versions and other settings via the `inputs` block in each module's `terragrunt.hcl`.

## Best Practices
- Apply modules in dependency order (VPC → EKS → controllers/addons → ArgoCD).
- Use `terragrunt run-all` with caution in production environments.
- Review and adjust IAM permissions as needed for your team and CI/CD systems.

---

For more details on each module, see the corresponding module directory under `/aws/iac/modules/`.
