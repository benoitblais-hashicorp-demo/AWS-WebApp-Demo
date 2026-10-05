output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS database credentials"
  value       = module.db.db_credentials_secret_arn
}

output "linux_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Linux VM credentials"
  value       = module.web.os_credentials_secret_arn
}

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = module.db.db_instance_endpoint
}

output "web_public_ip" {
  description = "The public IP of the web server"
  value       = module.web.public_ip
}

output "website_url" {
  description = "The final secured URL of your application"
  value       = "https://web-static.${var.public_hosted_zone}"
}
