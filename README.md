# AWS EKS Kubernetes Infrastructure as Code (IaC)

This repository provides a modular, production-ready Infrastructure as Code (IaC) solution for deploying and managing an Amazon EKS-based Kubernetes platform on AWS. It leverages Terraform modules, Terragrunt for orchestration, and Helm for Kubernetes application management.

## Features
- **Modular Terraform Modules:**
  - VPC, EKS, node groups, IAM roles, storage, ingress, cert-manager, ArgoCD, and more.
- **Terragrunt Environments:**
  - Environment-specific configuration (e.g., `dev`, `staging`) for easy multi-stage deployments.
- **Helm Integration:**
  - Deploys and manages Kubernetes applications (e.g., NGINX Ingress, cert-manager, ArgoCD) using Helm charts.
- **Secure Secrets Management:**
  - Sensitive values (e.g., ArgoCD admin password) are generated and stored in AWS SSM Parameter Store.
- **Dependency Management:**
  - Outputs from one module are passed to others using Terragrunt's dependency blocks.

## Directory Structure

- `aws/iac/modules/` — Reusable Terraform modules for each infrastructure component.
- `aws/iac/environments/` — Environment-specific Terragrunt configurations (e.g., `staging/`, `dev/`).
- `do/` — Example manifests and values for deploying applications (e.g., ArgoCD, cert-manager, ingress resources).
- `helm/` — Example Helm charts and values for monitoring stack (Prometheus, Grafana, etc.).

## Getting Started

### Prerequisites
- [Terraform](https://www.terraform.io/downloads.html)
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (configured with appropriate credentials)

### Usage

1. **Clone the repository:**
   ```sh
   git clone <this-repo-url>
   cd kubernetes/aws/iac/environments/staging
   ```

2. **Initialize Terragrunt:**
   ```sh
   terragrunt init
   ```

3. **Plan and Apply Infrastructure:**
   - To apply a specific module (e.g., EKS):
     ```sh
     cd eks
     terragrunt plan
     terragrunt apply
     ```
   - To apply all modules in order:
     ```sh
     terragrunt run-all plan
     terragrunt run-all apply
     ```

4. **Configure and Deploy Applications:**
   - Application-specific values and manifests are in the `do/` directory.
   - Helm chart values for monitoring stack are in the `helm/` directory.

### Customization
- Edit `env.hcl` in each environment for environment-specific variables.
- Adjust module variables in each module's `variables.tf` as needed.
- Update Helm chart versions and values in the `inputs` block of each module's `terragrunt.hcl`.

## Best Practices
- Apply modules in dependency order (VPC → EKS → controllers/addons → ArgoCD).
- Use `terragrunt run-all` with caution in production.
- Review IAM permissions and restrict as needed.
- Store sensitive values securely (e.g., SSM Parameter Store).

## References
- [Terraform](https://www.terraform.io/)
- [Terragrunt](https://terragrunt.gruntwork.io/)
- [AWS EKS](https://docs.aws.amazon.com/eks/)
- [Helm](https://helm.sh/)

---

For details on each module, see the corresponding directory under `aws/iac/modules/`.
