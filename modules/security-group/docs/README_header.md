# AWS Security Group Terraform Module

Terraform module to provision Amazon Web Services (AWS) Security Groups and their associated ingress and egress rules to control inbound and outbound traffic for AWS resources, ensuring a secure network perimeter.

## Permissions

To provision the AWS resources managed by this module, the IAM role or user running Terraform needs permissions such as:

- `AmazonEC2FullAccess` (or fine-grained privileges to manage Security Groups and Security Group Rules).
- Specific actions if scoping strictly:
  - `ec2:CreateSecurityGroup`
  - `ec2:DeleteSecurityGroup`
  - `ec2:DescribeSecurityGroups`
  - `ec2:AuthorizeSecurityGroupIngress`
  - `ec2:AuthorizeSecurityGroupEgress`
  - `ec2:RevokeSecurityGroupIngress`
  - `ec2:RevokeSecurityGroupEgress`
  - `ec2:DescribeSecurityGroupRules`
  - `ec2:ModifySecurityGroupRules`
  - `ec2:CreateTags`
  - `ec2:DeleteTags`

## Authentications

Authentication to AWS can be configured using one of the following methods, with preference given to OIDC and dynamic provider credentials in CI/CD environments.

### HCP Terraform / Terraform Enterprise Dynamic Credentials (OIDC)

Use dynamic provider credentials via OpenID Connect (OIDC) for secure, short-lived credentials when running in HCP Terraform or Terraform Enterprise.

- **Using environment variables (HCP Terraform Workspace)**

  - `TFC_AWS_PROVIDER_AUTH=true`
  - `TFC_AWS_RUN_ROLE_ARN=<aws-iam-role-arn>`

### OIDC with GitHub Actions

When using GitHub Actions, configure OIDC via the `aws-actions/configure-aws-credentials` action.

- **Using GitHub Actions**

  ```yaml
  - name: Configure AWS credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::111122223333:role/github-actions-role
      aws-region: us-east-1
  ```

### Static Access Keys

For local development or environments not supporting OIDC, use static IAM programmatic access keys.

- **Inside the provider block**

  ```hcl
  provider "aws" {
    region     = "us-east-1"
    access_key = "<aws-access-key-id>"
    secret_key = "<aws-secret-access-key>"
  }
  ```

- **Using environment variables**

  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_DEFAULT_REGION` (optional)

Documentation:

- [AWS Provider Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication)
- [Dynamic Provider Credentials in HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration)

## Features

- Complete foundational Security Group setup.
- Configurable inbound (ingress) rules using common protocols, CIDRs or Prefix Lists.
- Configurable outbound (egress) rules using common protocols, CIDRs or Prefix Lists.
- Helper sets of rules for well-known services (MySQL, HTTP, HTTPS, etc.).
- Tagging and lifecycle management for security group resources.

## Usage example

```hcl
module "security_group" {
  source  = "app.terraform.io/benoitblais-hashicorp/security-group/aws"
  version = "5.3.1"

  name        = "my-security-group"
  description = "Security group for user-service with custom ports open within VPC"
  vpc_id      = "vpc-12345678"

  ingress_cidr_blocks      = ["10.10.0.0/16"]
  ingress_rules            = ["https-443-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8090
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "10.10.0.0/16"
    },
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules             = ["all-all"]

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
```
