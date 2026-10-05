
##############################################################################
# Route53 Zone Data Discovery
##############################################################################

data "aws_route53_zone" "demo" {
  name = var.public_hosted_zone
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
  version = "0.0.3"

  name    = "alb-static"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false

  security_groups = [module.alb_sg.security_group_id]

  # Automated ACM Certificate Generation & Route53 Validation
  create_certificate      = true
  public_hosted_zone      = var.public_hosted_zone
  certificate_domain_name = "web-static.${var.public_hosted_zone}"

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
      port     = 443
      protocol = "HTTPS"
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
          module.web.os_credentials_secret_arn,
          module.db.db_credentials_secret_arn
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
  source  = "app.terraform.io/benoitblais-hashicorp/ec2-instance/aws"
  version = "0.0.1"

  name = "web-static"

  ami           = data.aws_ami.rhel9.id
  instance_type = "t3.small"

  create_os_credentials_secret = true

  user_data = templatefile("${path.module}/scripts/bootstrap_web-static.sh", {
    db_secret_arn    = "demo/database/static-demo-postgres"
    linux_secret_arn = "demo/linux/web-static"
    aws_region       = var.aws_region
    db_host          = module.db.db_instance_address
    db_port          = tostring(module.db.db_instance_port)
    db_name          = module.db.db_instance_name
    db_user          = "dbadmin"
    db_password      = module.db.db_instance_password
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

module "db" {
  source  = "app.terraform.io/benoitblais-hashicorp/db-instance/aws"
  version = "0.0.2"

  identifier     = "static-demo-postgres"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  db_name           = "appdb"
  username          = "dbadmin"

  # Network & Subnets
  create_db_subnet_group = true
  db_subnet_group_name   = "public-db-subnets"
  subnet_ids             = module.vpc.public_subnets
  vpc_security_group_ids = [module.db_sg.security_group_id]

  # Public access and automated Secrets Manager credentials
  publicly_accessible          = false
  create_db_credentials_secret = true
  skip_final_snapshot          = true
}
