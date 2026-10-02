#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting RHEL Web and DB initialization... (Static AWS-Native Secrets Demo)"

# 1. Update OS and install Python, PostgreSQL client, jq, and AWS CLI
dnf install -y postgresql python3 python3-pip jq unzip

# Install AWS CLI v2
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# 2. Retrieve Linux user credentials from AWS Secrets Manager
echo "Fetching Linux credentials from Secrets Manager..."
LINUX_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "${linux_secret_arn}" \
  --region "${aws_region}" \
  --query SecretString \
  --output text)

LINUXADMIN_PASS=$(echo "$LINUX_SECRET" | jq -r '.linuxadmin')
APPUSER_PASS=$(echo "$LINUX_SECRET" | jq -r '.appuser')

# 3. Setup OS users with passwords retrieved from Secrets Manager
useradd -m -s /bin/bash linuxadmin
echo "$LINUXADMIN_PASS" | passwd --stdin linuxadmin
usermod -aG wheel linuxadmin
echo "linuxadmin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/linuxadmin

useradd -m -s /bin/bash appuser
echo "$APPUSER_PASS" | passwd --stdin appuser

# Enable Password Authentication for SSH
cat << 'EOF_SSH' > /etc/ssh/sshd_config.d/00-force-password-auth.conf
PasswordAuthentication yes
KbdInteractiveAuthentication yes
PubkeyAuthentication yes
UsePAM yes
Match Address *
    PasswordAuthentication yes
EOF_SSH

sed -i 's/^[#]*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^[#]*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/*.conf || true

systemctl restart sshd

# 4. Retrieve database credentials from AWS Secrets Manager
echo "Fetching database credentials from Secrets Manager..."
DB_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "${db_secret_arn}" \
  --region "${aws_region}" \
  --query SecretString \
  --output text)

DB_HOST=$(echo "$DB_SECRET" | jq -r '.host')
DB_PORT=$(echo "$DB_SECRET" | jq -r '.port')
DB_NAME=$(echo "$DB_SECRET" | jq -r '.dbname')
DB_USER=$(echo "$DB_SECRET" | jq -r '.username')
DB_PASS=$(echo "$DB_SECRET" | jq -r '.password')

# 5. Install Flask and psycopg2 for the Python web app
pip3 install Flask psycopg2-binary pyOpenSSL cryptography

# 6. Generate a self-signed TLS certificate for internal HTTPS (ALB terminates public TLS via ACM)
mkdir -p /opt/app
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/app/key.pem \
  -out /opt/app/cert.pem \
  -subj "/CN=web-static.${private_zone}/O=Demo/C=CA" \
  -addext "subjectAltName=DNS:web-static.${private_zone},DNS:localhost,IP:127.0.0.1"
chmod 600 /opt/app/key.pem /opt/app/cert.pem

# 7. Seed the Database
export PGPASSWORD="$DB_PASS"
echo "Seeding the remote AWS RDS Database..."

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
CREATE TABLE IF NOT EXISTS demo_content (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    message TEXT
);
INSERT INTO demo_content (title, message)
SELECT 'AWS Native Secrets Demo', 'This information was successfully retrieved from an AWS RDS PostgreSQL Database using AWS Secrets Manager!'
WHERE NOT EXISTS (SELECT 1 FROM demo_content);
"

# 8. Write the Web Application — reads DB credentials from Secrets Manager at runtime
cat << 'EOF_APP' > /opt/app/app.py
import boto3
import json
import os

import psycopg2
from flask import Flask

app = Flask(__name__)

AWS_REGION = os.environ.get("AWS_REGION", "ca-central-1")
DB_SECRET_ARN = os.environ.get("DB_SECRET_ARN", "")


def get_db_credentials():
    client = boto3.client("secretsmanager", region_name=AWS_REGION)
    response = client.get_secret_value(SecretId=DB_SECRET_ARN)
    return json.loads(response["SecretString"])


@app.route("/")
def index():
    try:
        creds = get_db_credentials()
        conn = psycopg2.connect(
            host=creds["host"],
            port=creds["port"],
            database=creds["dbname"],
            user=creds["username"],
            password=creds["password"],
        )
        cur = conn.cursor()
        cur.execute("SELECT title, message FROM demo_content LIMIT 1;")
        row = cur.fetchone()
        cur.close()
        conn.close()

        if row:
            title, message = row
            return f"<h1>{title}</h1><p><strong>Status:</strong> {message}</p>"
        else:
            return "<h1>Hello World!</h1><p>Database connected, but no content found.</p>"

    except Exception as e:
        # Return a generic message; detailed error is logged server-side only
        app.logger.error("Application error: %s", str(e))
        return "<h1>Service Unavailable</h1><p>Could not retrieve data. Check server logs.</p>", 503


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=443, ssl_context=("/opt/app/cert.pem", "/opt/app/key.pem"))
EOF_APP

pip3 install boto3

# 9. Create the SystemD service for the web application
cat << EOF_SVC > /etc/systemd/system/demo-web.service
[Unit]
Description=Demo Flask Web App
After=network.target

[Service]
Environment="AWS_REGION=${aws_region}"
Environment="DB_SECRET_ARN=${db_secret_arn}"
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF_SVC

systemctl daemon-reload
systemctl enable demo-web
systemctl start demo-web

echo "Initialization Complete"
