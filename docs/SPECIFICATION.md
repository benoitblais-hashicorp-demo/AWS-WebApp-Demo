# AWS Native Secrets Integration Specification

## 1. Purpose

Define the target architecture and implementation requirements for a Terraform-based demonstration deploying AWS infrastructure with AWS-native secret management using AWS Secrets Manager and AWS Certificate Manager.

This specification is the source of truth for implementation behavior, guardrails, and acceptance criteria.

## 2. Scope

### 2.1 In Scope

- Provision AWS infrastructure with Terraform:
  - VPC and subnets
  - EC2 Linux VM for application hosting
  - RDS PostgreSQL
  - ALB for public ingress
  - Route53 records
- AWS-native secret management:
  - Store Linux VM credentials in AWS Secrets Manager
  - Store RDS database credentials in AWS Secrets Manager
  - EC2 instance retrieves credentials from Secrets Manager at bootstrap via IAM instance profile
- Use AWS Certificate Manager (ACM) for public-facing certificate on ALB.
- Use static AWS provider credentials (access key + secret key) for Terraform authentication.

### 2.2 Out of Scope

- HashiCorp Vault integration of any kind
- Dynamic/short-lived database credentials
- Vault PKI or any third-party PKI engine
- HCP Terraform JWT dynamic provider credentials

## 3. Platform Constraints

- No Vault cluster is required or used.
- AWS Secrets Manager is the sole secrets backend.
- Public certificate management uses AWS ACM.
- Static AWS credentials are provided as sensitive Terraform variables.

## 4. Architecture Requirements

### 4.1 AWS Infrastructure

- VPC with public and private subnets across at least two availability zones.
- ALB exposes HTTPS endpoint and forwards traffic to EC2 target(s).
- EC2 instance hosts the application workload.
- RDS PostgreSQL is reachable per security group policy defined for demo operations.
- Route53 records map public hostname to ALB.

### 4.2 AWS Secrets Manager Integration

- Linux VM credential secret path: `demo/linux/web-static`.
- Database credential secret path: `demo/database/web-static`.
- Both secrets use `recovery_window_in_days = 0` for easy demo teardown.
- The EC2 IAM role is granted least-privilege access (`secretsmanager:GetSecretValue`, `secretsmanager:DescribeSecret`) scoped to only the two demo secrets.
- Secrets are fetched at EC2 bootstrap via the AWS CLI using the instance's IAM profile.
- The Flask web application fetches database credentials from Secrets Manager at runtime using the boto3 SDK.
- Terraform must not hardcode plaintext secrets in source files.

### 4.3 Public TLS

- AWS ACM provides certificate for the public ALB listener.
- ALB HTTPS listener references ACM certificate ARN.
- EC2 instance uses a self-signed certificate for the internal ALB-to-instance HTTPS connection.

## 5. Repository and File Conventions

Root module uses canonical Terraform filenames:

- main.tf: root resources and module calls
- variables.tf: all input variables (required first, then optional/alphabetical)
- outputs.tf: outputs (alphabetical)
- providers.tf: provider configuration
- versions.tf: terraform and provider version constraints

`main.tf` includes a dedicated `AWS Secrets Manager — Core Configuration` section that defines all secret resources and random password generation at the top of the file.

Shared data sources are defined in `main.tf` and placed next to the resources that consume them.

Documentation files:

- docs/README_header.md
- docs/README_footer.md
- docs/SPECIFICATION.md (this file)

## 6. Security Requirements

- Mark sensitive variables (`aws_access_key_id`, `aws_secret_access_key`) with `sensitive = true`.
- Do not commit local Terraform state or `.terraform` directories.
- Secrets must never appear in Terraform outputs or user_data logs in plaintext.
- The EC2 IAM policy grants read access to only the two specific Secrets Manager secret ARNs (least privilege).
- IMDSv2 (`http_tokens = "required"`) is enforced on the EC2 instance.

## 7. Functional Requirements

### FR-1 Infrastructure Provisioning

Terraform apply provisions VPC, ALB, EC2, RDS, and DNS resources required for the demo.

### FR-2 Linux Credentials in Secrets Manager

Linux VM credentials are stored in Secrets Manager at `demo/linux/web-static` and retrieved by the EC2 instance at bootstrap via its IAM instance profile.

### FR-3 Database Credentials in Secrets Manager

RDS credentials are stored in Secrets Manager at `demo/database/web-static`. The web application fetches them at runtime using the boto3 SDK via the instance's IAM role.

### FR-4 Public HTTPS

Public application URL is served through ALB HTTPS using an AWS ACM certificate.

## 8. Non-Functional Requirements

- Maintainable Terraform structure and naming consistency.
- Compatibility with HCP Terraform / VCS-driven CI workflow.
- Clear, reproducible demo steps in documentation.
- No Vault or third-party secret backend dependency.

## 9. Acceptance Criteria

### AC-1

Repository follows canonical root file naming convention.

### AC-2

No resource blocks or documentation references rely on HashiCorp Vault.

### AC-3

No resource blocks reference `vault_*` providers, resources, or data sources.

### AC-4

Public ALB endpoint presents a valid ACM-backed certificate.

### AC-5

Secrets Manager secrets `demo/linux/web-static` and `demo/database/web-static` are created and accessible by the EC2 instance IAM role.

### AC-6

The web application successfully connects to RDS using credentials fetched from Secrets Manager at runtime.

## 10. Documentation Requirements

- README content must reflect the AWS-native secrets architecture.
- Demo instructions must describe:
  - Retrieving Linux VM credentials from Secrets Manager via AWS CLI
  - Verifying the web application reads DB credentials from Secrets Manager at runtime
  - Verifying public certificate via AWS ACM on ALB

## 11. Risks and Mitigations

- Risk: Secret exposure through bootstrap scripts.
  - Mitigation: Secrets are fetched from Secrets Manager at runtime using IAM; no plaintext credentials are embedded in user_data.
- Risk: Static IAM credentials compromise.
  - Mitigation: Use least-privilege IAM policy; rotate credentials after demo; store as sensitive Terraform variables.
- Risk: Misaligned docs and code.
  - Mitigation: maintain this specification and regenerate README from docs inputs.

## 12. Change Control

Any change affecting architecture decisions in this file requires synchronized updates to:

- AGENTS.md
- docs/README_header.md
- Terraform implementation in root module files
