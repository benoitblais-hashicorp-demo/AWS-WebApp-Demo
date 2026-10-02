##############################################################################
# AWS Secrets Manager — Core Configuration
# Stores all secrets natively in AWS: Linux VM credentials and DB password.
##############################################################################

resource "random_password" "os_linuxadmin_password" {
  length           = 32
  special          = true
  override_special = "-_"
}

resource "random_password" "os_appuser_password" {
  length           = 32
  special          = true
  override_special = "-_"
}

resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "linux_vm_credentials" {
  name        = "demo/linux/web-static"
  description = "Linux VM credentials for the web server EC2 instance"

  recovery_window_in_days = 0 # Immediate deletion for demo cleanup
}

resource "aws_secretsmanager_secret_version" "linux_vm_credentials" {
  secret_id = aws_secretsmanager_secret.linux_vm_credentials.id
  secret_string = jsonencode({
    linuxadmin = random_password.os_linuxadmin_password.result
    appuser    = random_password.os_appuser_password.result
  })
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "demo/database/web-static"
  description = "RDS PostgreSQL master credentials for the demo database"

  recovery_window_in_days = 0 # Immediate deletion for demo cleanup
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password.result
    host     = aws_db_instance.db.address
    port     = tostring(aws_db_instance.db.port)
    dbname   = aws_db_instance.db.db_name
  })

  depends_on = [aws_db_instance.db]
}

##############################################################################
# ACM — Public Certificate for ALB
##############################################################################

data "aws_route53_zone" "demo" {
  name = var.public_hosted_zone
}

resource "aws_acm_certificate" "public" {
  domain_name       = "web-static.${var.public_hosted_zone}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "public_validation" {
  for_each = {
    for dvo in aws_acm_certificate.public.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.demo.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "public" {
  certificate_arn         = aws_acm_certificate.public.arn
  validation_record_fqdns = [for record in aws_route53_record.public_validation : record.fqdn]
}

##############################################################################
# Networking — VPC
##############################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "app.terraform.io/benoitblais-hashicorp/vpc/aws"
  version = "0.0.1"

  name = "web-infra-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = [for k, v in slice(data.aws_availability_zones.available.names, 0, 2) : cidrsubnet(var.vpc_cidr, 8, k + 1)]
  private_subnets = [for k, v in slice(data.aws_availability_zones.available.names, 0, 2) : cidrsubnet(var.vpc_cidr, 8, k + 10)]

  map_public_ip_on_launch = true

  enable_nat_gateway     = true
  single_nat_gateway     = true # Cost savings: 1 NAT GW for the demo instead of 1 per AZ
  one_nat_gateway_per_az = false

  enable_vpn_gateway = false
}

##############################################################################
# Security Groups — ALB
##############################################################################

module "alb_sg" {
  source  = "app.terraform.io/benoitblais-hashicorp/security-group/aws"
  version = "0.0.2"

  name        = "alb-static-sg"
  description = "Security group for ALB allowing public HTTPS. HTTP is permitted only for 301 redirects."
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]
}

##############################################################################
# Security Groups — Web Server
##############################################################################

module "web_sg" {
  source  = "app.terraform.io/benoitblais-hashicorp/security-group/aws"
  version = "0.0.2"

  name        = "web-static-sg"
  description = "Security group for web server allowing traffic only from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      description              = "HTTP from ALB"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Access from Admin Laptop for Demo Verification"
      cidr_blocks = var.admin_laptop_ip != "" ? var.admin_laptop_ip : "127.0.0.1/32"
    }
  ]

  egress_rules = ["all-all"]
}

##############################################################################
# ALB — Load Balancer, Listeners, Target Group
##############################################################################

module "alb" {
  source  = "app.terraform.io/benoitblais-hashicorp/alb/aws"
  version = "0.0.1"

  name    = "alb-static"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false

  security_groups = [module.alb_sg.security_group_id]

  listeners = {
    http-80 = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https-443 = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = aws_acm_certificate_validation.public.certificate_arn
      forward = {
        target_group_key = "web-static-tg"
      }
    }
  }

  target_groups = {
    web-static-tg = {
      name_prefix       = "webstc"
      protocol          = "HTTP"
      port              = 8080
      target_type       = "instance"
      create_attachment = false
    }
  }
}

resource "aws_lb_target_group_attachment" "web_attachment" {
  target_group_arn = module.alb.target_groups["web-static-tg"].arn
  target_id        = module.web.id
  port             = 8080
}

##############################################################################
# Route53 — Public DNS Record
##############################################################################

resource "aws_route53_record" "web_dns_record" {
  zone_id = data.aws_route53_zone.demo.zone_id
  name    = "web-static.${var.public_hosted_zone}"
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

##############################################################################
# IAM — EC2 Instance Role (SSM + Secrets Manager read access)
##############################################################################

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "web_role" {
  name = "web_static_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core_attachment" {
  role       = aws_iam_role.web_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "secrets_read" {
  name        = "web_static_secrets_read"
  description = "Allow the web server EC2 instance to read demo secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.linux_vm_credentials.arn,
          aws_secretsmanager_secret.db_credentials.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_read_attachment" {
  role       = aws_iam_role.web_role.name
  policy_arn = aws_iam_policy.secrets_read.arn
}

resource "aws_iam_instance_profile" "web_profile" {
  name = "web_static_profile"
  role = aws_iam_role.web_role.name
}

##############################################################################
# EC2 — Web Server
##############################################################################

data "aws_ami" "rhel9" {
  most_recent = true
  owners      = ["309956199498"] # Official Red Hat AWS account

  filter {
    name   = "name"
    values = ["RHEL-9.*_HVM-*-x86_64-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

module "web" {
  source = "./modules/ec2-instance"

  name = "web-static"

  ami           = data.aws_ami.rhel9.id
  instance_type = "t3.small"

  user_data = templatefile("${path.module}/scripts/bootstrap_web-static.sh", {
    db_secret_arn    = aws_secretsmanager_secret.db_credentials.arn
    linux_secret_arn = aws_secretsmanager_secret.linux_vm_credentials.arn
    aws_region       = var.aws_region
    db_host          = aws_db_instance.db.address
    db_port          = tostring(aws_db_instance.db.port)
    db_name          = aws_db_instance.db.db_name
    db_user          = "dbadmin"
    db_password      = random_password.db_password.result
  })

  user_data_replace_on_change = true

  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.web_sg.security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.web_profile.name

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
}

##############################################################################
# Security Groups — RDS
##############################################################################

module "db_sg" {
  source  = "app.terraform.io/benoitblais-hashicorp/security-group/aws"
  version = "0.0.2"

  name        = "db-static-sg"
  description = "Security group for RDS allowing Web Server and Admin access"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "postgresql-tcp"
      cidr_blocks = var.admin_laptop_ip != "" ? var.admin_laptop_ip : "127.0.0.1/32"
      description = "Access from Admin Laptop for Demo Verification"
    }
  ]

  ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.web_sg.security_group_id
      description              = "Access from internal Web Server"
    }
  ]

  egress_rules = ["all-all"]
}

##############################################################################
# RDS — PostgreSQL
##############################################################################

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "public-db-subnets"

  subnet_ids = module.vpc.public_subnets
}

resource "aws_db_instance" "db" {
  identifier        = "static-demo-postgres"
  engine            = "postgres"
  engine_version    = "16" # Latest supported major version
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "appdb"
  username          = "dbadmin"
  password          = random_password.db_password.result

  publicly_accessible    = true
  vpc_security_group_ids = [module.db_sg.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot    = true
}
