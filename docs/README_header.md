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

Terraform authenticates to AWS using static credentials supplied as sensitive input variables (`aws_access_key_id` and `aws_secret_access_key`). These should be stored as sensitive workspace variables and never committed to source control.

```bash
# Example: set as environment variables for local runs
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
export AWS_REGION="ca-central-1"
```

Alternatively, configure the variables in your HCP Terraform workspace as sensitive Terraform variables.
