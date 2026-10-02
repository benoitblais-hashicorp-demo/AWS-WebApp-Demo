<!-- BEGIN_TF_DOCS -->
# AWS Native Secrets on AWS

This repository provides an end-to-end Terraform architecture demonstrating AWS-native secret management on AWS. It orchestrates core AWS infrastructure (VPC, EC2, RDS, ALB) with all secrets — Linux VM credentials and database credentials — stored and retrieved natively via AWS Secrets Manager.

## What this demo demonstrates

This demo showcases how AWS-native services can centralize and automate secret management across infrastructure and applications without a third-party secrets engine. It highlights how EC2 workloads can consume secrets from AWS Secrets Manager using their IAM instance profile, avoiding hardcoded credentials entirely.

## Features

* **AWS Secrets Manager**: Storage for Linux VM credentials and RDS database credentials, retrieved securely at bootstrap and runtime using IAM roles.
* **AWS IAM Instance Profile**: Least-privilege role granting the EC2 instance access exclusively to its two Secrets Manager secrets.
* **AWS ACM**: Public-facing ALB certificates managed by AWS Certificate Manager with automated DNS validation via Route53.
* **AWS SSM Session Manager**: Secure shell access to the EC2 instance without opening inbound SSH to the internet.
* **HashiCorp Terraform**: Standardized infrastructure-as-code modules for AWS deployments (VPC, EC2, ALB, RDS, Security Groups).

## Demo Components

* **Network Architecture**: Foundational AWS VPC, Public/Private Subnets, and NAT Gateway.
* **Web Application**: An EC2 instance bootstrapped with OS user credentials pulled from Secrets Manager, serving a Flask application that reads database credentials from Secrets Manager at request time.
* **Database**: An AWS RDS PostgreSQL instance serving as the application backend.
* **Load Balancing & DNS**: Application Load Balancer securing incoming internet traffic with an ACM certificate, mapped via Route53.

## How this demo works

Terraform provisions the AWS networking and compute infrastructure. Random passwords are generated for the Linux OS users and the RDS master user. These are stored as JSON documents in two AWS Secrets Manager secrets. The EC2 instance's bootstrap script fetches both secrets via the AWS CLI using its IAM instance profile, sets up the OS users, seeds the database, and starts the Flask web application. The Flask app fetches the database credentials from Secrets Manager on every request using the boto3 SDK and the same IAM role.

## How to Conduct the Demo

*Prerequisite*: Add your laptop IP to the Terraform `admin_laptop_ip` variable if you want local SSH or direct database access during the demo.

1. **Showcase the Web Application:**
   Navigate to the `website_url` output (e.g. `https://web-static.benoit-blais.sbx.hashidemos.io`) to verify the secured application is running with an ACM-backed public certificate.

2. **Retrieve Linux Credentials from Secrets Manager:**
   Run the following AWS CLI command to retrieve the Linux VM credentials stored by Terraform:

   ```bash
   aws secretsmanager get-secret-value \
     --secret-id demo/linux/web-static \
     --region ca-central-1 \
     --query SecretString \
     --output text | jq .
   ```

   The output will show the `linuxadmin` and `appuser` passwords. Use the `linuxadmin` credential to SSH into the EC2 instance.

3. **Inspect Database Credentials in Secrets Manager:**
   Run the following command to view the database credentials stored at provisioning time:

   ```bash
   aws secretsmanager get-secret-value \
     --secret-id demo/database/web-static \
     --region ca-central-1 \
     --query SecretString \
     --output text | jq .
   ```

   Use the returned values to open a connection in pgAdmin4:

   ```text
   Host name/address: <rds_endpoint output>
   Port:              5432
   Maintenance database: appdb
   Username: <username from secret>
   Password: <password from secret>
   ```

4. **Demonstrate Runtime Secret Retrieval:**
   While connected to the EC2 instance, confirm the application is fetching credentials from Secrets Manager on every request:

   ```bash
   journalctl -u demo-web --no-pager -n 20
   ```

   Update a record in the `demo_content` table to showcase live data:

   ```sql
   UPDATE demo_content SET message = 'Live AWS Secrets Manager Demo Successful!' WHERE id = 1;
   ```

   Reload the web page to see the updated content.

5. **Verify the ACM Certificate on the ALB:**
   Open a browser or run the following to confirm the public certificate is valid and issued by ACM:

   ```bash
   curl -v https://web-static.benoit-blais.sbx.hashidemos.io 2>&1 | grep -E "subject|issuer|expire"
   ```

## Expected Behavior

* The web server outputs a success message pulling live data from the database.
* Linux VM credentials are retrievable from Secrets Manager using authorized AWS CLI access.
* The Flask application uses boto3 to retrieve database credentials from Secrets Manager on each request — no hardcoded passwords anywhere in the application code.

## Permissions

### AWS Provider Permissions

**Required IAM Permissions**: The role or user must have sufficient rights to manage VPCs, Subnets, EC2 Instances, Route53 Zones/Records, Application Load Balancers, Target Groups, ACM Certificates, IAM Roles/Policies/Profiles, RDS instances, and Secrets Manager secrets.

## Authentications

### AWS Provider Authentication

Authentication is handled via HCP Terraform Dynamic Provider Credentials. No static AWS credentials are used or required. The HCP Terraform workspace is configured to assume an AWS IAM role using OIDC at plan and apply time.

For local debugging, standard AWS environment variables or a shared credentials file are supported:

```bash
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
export AWS_REGION="ca-central-1"
```

## Documentation

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_aws"></a> [aws](#requirement\_aws) (~> 5.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Modules

The following Modules are called:

### <a name="module_alb"></a> [alb](#module\_alb)

Source: app.terraform.io/benoitblais-hashicorp/alb/aws

Version: 0.0.1

### <a name="module_alb_sg"></a> [alb\_sg](#module\_alb\_sg)

Source: ./modules/security-group

Version:

### <a name="module_db_sg"></a> [db\_sg](#module\_db\_sg)

Source: ./modules/security-group

Version:

### <a name="module_vpc"></a> [vpc](#module\_vpc)

Source: app.terraform.io/benoitblais-hashicorp/vpc/aws

Version: 0.0.1

### <a name="module_web"></a> [web](#module\_web)

Source: ./modules/ec2-instance

Version:

### <a name="module_web_sg"></a> [web\_sg](#module\_web\_sg)

Source: ./modules/security-group

Version:

## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_admin_laptop_ip"></a> [admin\_laptop\_ip](#input\_admin\_laptop\_ip)

Description: (Optional) Public IP of your local laptop allowed to connect directly to the EC2 and RDS instances for demo verification. Needs /32 suffix.

Type: `string`

Default: `""`

### <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region)

Description: (Optional) The AWS region to deploy resources into.

Type: `string`

Default: `"ca-central-1"`

### <a name="input_private_hosted_zone"></a> [private\_hosted\_zone](#input\_private\_hosted\_zone)

Description: (Optional) Private Route53 Hosted Zone domain name used for internal DNS records.

Type: `string`

Default: `"benoit-blais.sbx.hashidemos.local"`

### <a name="input_public_hosted_zone"></a> [public\_hosted\_zone](#input\_public\_hosted\_zone)

Description: (Optional) Public Route53 Hosted Zone domain name for ACM certificates and external DNS.

Type: `string`

Default: `"benoit-blais.sbx.hashidemos.io"`

### <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr)

Description: (Optional) The CIDR block for the VPC.

Type: `string`

Default: `"10.0.0.0/16"`

## Resources

The following resources are used by this module:

- [aws_acm_certificate.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) (resource)
- [aws_acm_certificate_validation.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) (resource)
- [aws_db_instance.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) (resource)
- [aws_db_subnet_group.db_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) (resource)
- [aws_iam_instance_profile.web_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) (resource)
- [aws_iam_policy.secrets_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) (resource)
- [aws_iam_role.web_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
- [aws_iam_role_policy_attachment.secrets_read_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) (resource)
- [aws_iam_role_policy_attachment.ssm_core_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) (resource)
- [aws_lb_target_group_attachment.web_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) (resource)
- [aws_route53_record.public_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) (resource)
- [aws_route53_record.web_dns_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) (resource)
- [aws_secretsmanager_secret.db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) (resource)
- [aws_secretsmanager_secret.linux_vm_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) (resource)
- [aws_secretsmanager_secret_version.db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) (resource)
- [aws_secretsmanager_secret_version.linux_vm_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) (resource)
- [random_password.db_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [random_password.os_appuser_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [random_password.os_linuxadmin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [aws_ami.rhel9](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) (data source)
- [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) (data source)
- [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) (data source)
- [aws_route53_zone.demo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) (data source)

## Outputs

The following outputs are exported:

### <a name="output_db_credentials_secret_arn"></a> [db\_credentials\_secret\_arn](#output\_db\_credentials\_secret\_arn)

Description: ARN of the Secrets Manager secret containing the RDS database credentials

### <a name="output_linux_credentials_secret_arn"></a> [linux\_credentials\_secret\_arn](#output\_linux\_credentials\_secret\_arn)

Description: ARN of the Secrets Manager secret containing the Linux VM credentials

### <a name="output_rds_endpoint"></a> [rds\_endpoint](#output\_rds\_endpoint)

Description: The endpoint of the RDS instance

### <a name="output_web_public_ip"></a> [web\_public\_ip](#output\_web\_public\_ip)

Description: The public IP of the web server

### <a name="output_website_url"></a> [website\_url](#output\_website\_url)

Description: The final secured URL of your application

<!-- markdownlint-enable -->
## External Documentation

The following external documentation was used to develop this configuration:

* [AWS Provider — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [AWS Secrets Manager — Developer Guide](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
* [AWS Secrets Manager — Terraform Resource: aws\_secretsmanager\_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)
* [AWS IAM — Terraform Resource: aws\_iam\_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
* [AWS Certificate Manager (ACM) — User Guide](https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html)
* [AWS ACM — Terraform Resource: aws\_acm\_certificate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate)
* [AWS RDS PostgreSQL — User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
* [AWS EC2 IMDSv2 — Instance Metadata](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)
* [boto3 Secrets Manager — Python SDK](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager.html)
* [AWS CLI — get-secret-value](https://docs.aws.amazon.com/cli/latest/reference/secretsmanager/get-secret-value.html)
<!-- END_TF_DOCS -->