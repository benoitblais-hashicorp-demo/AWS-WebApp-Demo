<!-- BEGIN_TF_DOCS -->
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

## Documentation

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.0)

- <a name="requirement_aws"></a> [aws](#requirement\_aws) (~> 5.0)

## Modules

No modules.

## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_computed_egress_rules"></a> [computed\_egress\_rules](#input\_computed\_egress\_rules)

Description: List of computed egress rules to create by name

Type: `list(string)`

Default: `[]`

### <a name="input_computed_egress_with_cidr_blocks"></a> [computed\_egress\_with\_cidr\_blocks](#input\_computed\_egress\_with\_cidr\_blocks)

Description: List of computed egress rules to create where 'cidr\_blocks' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_computed_egress_with_ipv6_cidr_blocks"></a> [computed\_egress\_with\_ipv6\_cidr\_blocks](#input\_computed\_egress\_with\_ipv6\_cidr\_blocks)

Description: List of computed egress rules to create where 'ipv6\_cidr\_blocks' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_computed_egress_with_prefix_list_ids"></a> [computed\_egress\_with\_prefix\_list\_ids](#input\_computed\_egress\_with\_prefix\_list\_ids)

Description: List of computed egress rules to create where 'prefix\_list\_ids' is used only

Type: `list(map(string))`

Default: `[]`

### <a name="input_computed_egress_with_self"></a> [computed\_egress\_with\_self](#input\_computed\_egress\_with\_self)

Description: List of computed egress rules to create where 'self' is defined

Type: `list(map(string))`

Default: `[]`

### <a name="input_computed_egress_with_source_security_group_id"></a> [computed\_egress\_with\_source\_security\_group\_id](#input\_computed\_egress\_with\_source\_security\_group\_id)

Description: List of computed egress rules to create where 'source\_security\_group\_id' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_computed_ingress_rules"></a> [computed\_ingress\_rules](#input\_computed\_ingress\_rules)

Description: List of computed ingress rules to create by name

Type: `list(string)`

Default: `[]`

### <a name="input_computed_ingress_with_cidr_blocks"></a> [computed\_ingress\_with\_cidr\_blocks](#input\_computed\_ingress\_with\_cidr\_blocks)

Description: List of computed ingress rules to create where 'cidr\_blocks' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_computed_ingress_with_ipv6_cidr_blocks"></a> [computed\_ingress\_with\_ipv6\_cidr\_blocks](#input\_computed\_ingress\_with\_ipv6\_cidr\_blocks)

Description: List of computed ingress rules to create where 'ipv6\_cidr\_blocks' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_computed_ingress_with_self"></a> [computed\_ingress\_with\_self](#input\_computed\_ingress\_with\_self)

Description: List of computed ingress rules to create where 'self' is defined

Type: `list(map(string))`

Default: `[]`

### <a name="input_computed_ingress_with_source_security_group_id"></a> [computed\_ingress\_with\_source\_security\_group\_id](#input\_computed\_ingress\_with\_source\_security\_group\_id)

Description: List of computed ingress rules to create where 'source\_security\_group\_id' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_create"></a> [create](#input\_create)

Description: Whether to create security group and all rules

Type: `bool`

Default: `true`

### <a name="input_create_sg"></a> [create\_sg](#input\_create\_sg)

Description: Whether to create security group

Type: `bool`

Default: `true`

### <a name="input_create_timeout"></a> [create\_timeout](#input\_create\_timeout)

Description: Time to wait for a security group to be created

Type: `string`

Default: `"10m"`

### <a name="input_delete_timeout"></a> [delete\_timeout](#input\_delete\_timeout)

Description: Time to wait for a security group to be deleted

Type: `string`

Default: `"15m"`

### <a name="input_description"></a> [description](#input\_description)

Description: Description of security group

Type: `string`

Default: `"Security Group managed by Terraform"`

### <a name="input_egress_cidr_blocks"></a> [egress\_cidr\_blocks](#input\_egress\_cidr\_blocks)

Description: List of IPv4 CIDR ranges to use on all egress rules

Type: `list(string)`

Default:

```json
[
  "0.0.0.0/0"
]
```

### <a name="input_egress_ipv6_cidr_blocks"></a> [egress\_ipv6\_cidr\_blocks](#input\_egress\_ipv6\_cidr\_blocks)

Description: List of IPv6 CIDR ranges to use on all egress rules

Type: `list(string)`

Default:

```json
[
  "::/0"
]
```

### <a name="input_egress_prefix_list_ids"></a> [egress\_prefix\_list\_ids](#input\_egress\_prefix\_list\_ids)

Description: List of prefix list IDs (for allowing access to VPC endpoints) to use on all egress rules

Type: `list(string)`

Default: `[]`

### <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules)

Description: List of egress rules to create by name

Type: `list(string)`

Default: `[]`

### <a name="input_egress_with_cidr_blocks"></a> [egress\_with\_cidr\_blocks](#input\_egress\_with\_cidr\_blocks)

Description: List of egress rules to create where 'cidr\_blocks' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_egress_with_ipv6_cidr_blocks"></a> [egress\_with\_ipv6\_cidr\_blocks](#input\_egress\_with\_ipv6\_cidr\_blocks)

Description: List of egress rules to create where 'ipv6\_cidr\_blocks' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_egress_with_prefix_list_ids"></a> [egress\_with\_prefix\_list\_ids](#input\_egress\_with\_prefix\_list\_ids)

Description: List of egress rules to create where 'prefix\_list\_ids' is used only

Type: `list(map(string))`

Default: `[]`

### <a name="input_egress_with_self"></a> [egress\_with\_self](#input\_egress\_with\_self)

Description: List of egress rules to create where 'self' is defined

Type: `list(map(string))`

Default: `[]`

### <a name="input_egress_with_source_security_group_id"></a> [egress\_with\_source\_security\_group\_id](#input\_egress\_with\_source\_security\_group\_id)

Description: List of egress rules to create where 'source\_security\_group\_id' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_ingress_cidr_blocks"></a> [ingress\_cidr\_blocks](#input\_ingress\_cidr\_blocks)

Description: List of IPv4 CIDR ranges to use on all ingress rules

Type: `list(string)`

Default: `[]`

### <a name="input_ingress_ipv6_cidr_blocks"></a> [ingress\_ipv6\_cidr\_blocks](#input\_ingress\_ipv6\_cidr\_blocks)

Description: List of IPv6 CIDR ranges to use on all ingress rules

Type: `list(string)`

Default: `[]`

### <a name="input_ingress_prefix_list_ids"></a> [ingress\_prefix\_list\_ids](#input\_ingress\_prefix\_list\_ids)

Description: List of prefix list IDs (for allowing access to VPC endpoints) to use on all ingress rules

Type: `list(string)`

Default: `[]`

### <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules)

Description: List of ingress rules to create by name

Type: `list(string)`

Default: `[]`

### <a name="input_ingress_with_cidr_blocks"></a> [ingress\_with\_cidr\_blocks](#input\_ingress\_with\_cidr\_blocks)

Description: List of ingress rules to create where 'cidr\_blocks' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_ingress_with_ipv6_cidr_blocks"></a> [ingress\_with\_ipv6\_cidr\_blocks](#input\_ingress\_with\_ipv6\_cidr\_blocks)

Description: List of ingress rules to create where 'ipv6\_cidr\_blocks' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_ingress_with_prefix_list_ids"></a> [ingress\_with\_prefix\_list\_ids](#input\_ingress\_with\_prefix\_list\_ids)

Description: List of ingress rules to create where 'prefix\_list\_ids' is used only

Type: `list(map(string))`

Default: `[]`

### <a name="input_ingress_with_self"></a> [ingress\_with\_self](#input\_ingress\_with\_self)

Description: List of ingress rules to create where 'self' is defined

Type: `list(map(string))`

Default: `[]`

### <a name="input_ingress_with_source_security_group_id"></a> [ingress\_with\_source\_security\_group\_id](#input\_ingress\_with\_source\_security\_group\_id)

Description: List of ingress rules to create where 'source\_security\_group\_id' is used

Type: `list(map(string))`

Default: `[]`

### <a name="input_name"></a> [name](#input\_name)

Description: Name of security group - not required if create\_sg is false

Type: `string`

Default: `null`

### <a name="input_number_of_computed_egress_rules"></a> [number\_of\_computed\_egress\_rules](#input\_number\_of\_computed\_egress\_rules)

Description: Number of computed egress rules to create by name

Type: `number`

Default: `0`

### <a name="input_number_of_computed_egress_with_cidr_blocks"></a> [number\_of\_computed\_egress\_with\_cidr\_blocks](#input\_number\_of\_computed\_egress\_with\_cidr\_blocks)

Description: Number of computed egress rules to create where 'cidr\_blocks' is used

Type: `number`

Default: `0`

### <a name="input_number_of_computed_egress_with_ipv6_cidr_blocks"></a> [number\_of\_computed\_egress\_with\_ipv6\_cidr\_blocks](#input\_number\_of\_computed\_egress\_with\_ipv6\_cidr\_blocks)

Description: Number of computed egress rules to create where 'ipv6\_cidr\_blocks' is used

Type: `number`

Default: `0`

### <a name="input_number_of_computed_egress_with_prefix_list_ids"></a> [number\_of\_computed\_egress\_with\_prefix\_list\_ids](#input\_number\_of\_computed\_egress\_with\_prefix\_list\_ids)

Description: Number of computed egress rules to create where 'prefix\_list\_ids' is used only

Type: `number`

Default: `0`

### <a name="input_number_of_computed_egress_with_self"></a> [number\_of\_computed\_egress\_with\_self](#input\_number\_of\_computed\_egress\_with\_self)

Description: Number of computed egress rules to create where 'self' is defined

Type: `number`

Default: `0`

### <a name="input_number_of_computed_egress_with_source_security_group_id"></a> [number\_of\_computed\_egress\_with\_source\_security\_group\_id](#input\_number\_of\_computed\_egress\_with\_source\_security\_group\_id)

Description: Number of computed egress rules to create where 'source\_security\_group\_id' is used

Type: `number`

Default: `0`

### <a name="input_number_of_computed_ingress_rules"></a> [number\_of\_computed\_ingress\_rules](#input\_number\_of\_computed\_ingress\_rules)

Description: Number of computed ingress rules to create by name

Type: `number`

Default: `0`

### <a name="input_number_of_computed_ingress_with_cidr_blocks"></a> [number\_of\_computed\_ingress\_with\_cidr\_blocks](#input\_number\_of\_computed\_ingress\_with\_cidr\_blocks)

Description: Number of computed ingress rules to create where 'cidr\_blocks' is used

Type: `number`

Default: `0`

### <a name="input_number_of_computed_ingress_with_ipv6_cidr_blocks"></a> [number\_of\_computed\_ingress\_with\_ipv6\_cidr\_blocks](#input\_number\_of\_computed\_ingress\_with\_ipv6\_cidr\_blocks)

Description: Number of computed ingress rules to create where 'ipv6\_cidr\_blocks' is used

Type: `number`

Default: `0`

### <a name="input_number_of_computed_ingress_with_prefix_list_ids"></a> [number\_of\_computed\_ingress\_with\_prefix\_list\_ids](#input\_number\_of\_computed\_ingress\_with\_prefix\_list\_ids)

Description: Number of computed ingress rules to create where 'prefix\_list\_ids' is used

Type: `number`

Default: `0`

### <a name="input_number_of_computed_ingress_with_self"></a> [number\_of\_computed\_ingress\_with\_self](#input\_number\_of\_computed\_ingress\_with\_self)

Description: Number of computed ingress rules to create where 'self' is defined

Type: `number`

Default: `0`

### <a name="input_number_of_computed_ingress_with_source_security_group_id"></a> [number\_of\_computed\_ingress\_with\_source\_security\_group\_id](#input\_number\_of\_computed\_ingress\_with\_source\_security\_group\_id)

Description: Number of computed ingress rules to create where 'source\_security\_group\_id' is used

Type: `number`

Default: `0`

### <a name="input_putin_khuylo"></a> [putin\_khuylo](#input\_putin\_khuylo)

Description: Do you agree that Putin doesn't respect Ukrainian sovereignty and territorial integrity? More info: https://en.wikipedia.org/wiki/Putin_khuylo!

Type: `bool`

Default: `true`

### <a name="input_revoke_rules_on_delete"></a> [revoke\_rules\_on\_delete](#input\_revoke\_rules\_on\_delete)

Description: Instruct Terraform to revoke all of the Security Groups attached ingress and egress rules before deleting the rule itself. Enable for EMR.

Type: `bool`

Default: `false`

### <a name="input_rules"></a> [rules](#input\_rules)

Description: Map of known security group rules (define as 'name' = ['from port', 'to port', 'protocol', 'description'])

Type: `map(list(any))`

Default:

```json
{
  "_": [
    "",
    "",
    ""
  ],
  "activemq-5671-tcp": [
    5671,
    5671,
    "tcp",
    "ActiveMQ AMQP"
  ],
  "activemq-61614-tcp": [
    61614,
    61614,
    "tcp",
    "ActiveMQ STOMP"
  ],
  "activemq-61617-tcp": [
    61617,
    61617,
    "tcp",
    "ActiveMQ OpenWire"
  ],
  "activemq-61619-tcp": [
    61619,
    61619,
    "tcp",
    "ActiveMQ WebSocket"
  ],
  "activemq-8883-tcp": [
    8883,
    8883,
    "tcp",
    "ActiveMQ MQTT"
  ],
  "alertmanager-9093-tcp": [
    9093,
    9093,
    "tcp",
    "Alert Manager"
  ],
  "alertmanager-9094-tcp": [
    9094,
    9094,
    "tcp",
    "Alert Manager Cluster"
  ],
  "all-all": [
    -1,
    -1,
    "-1",
    "All protocols"
  ],
  "all-icmp": [
    -1,
    -1,
    "icmp",
    "All IPV4 ICMP"
  ],
  "all-ipv6-icmp": [
    -1,
    -1,
    58,
    "All IPV6 ICMP"
  ],
  "all-tcp": [
    0,
    65535,
    "tcp",
    "All TCP ports"
  ],
  "all-udp": [
    0,
    65535,
    "udp",
    "All UDP ports"
  ],
  "carbon-admin-tcp": [
    2004,
    2004,
    "tcp",
    "Carbon admin"
  ],
  "carbon-gui-udp": [
    8081,
    8081,
    "tcp",
    "Carbon GUI"
  ],
  "carbon-line-in-tcp": [
    2003,
    2003,
    "tcp",
    "Carbon line-in"
  ],
  "carbon-line-in-udp": [
    2003,
    2003,
    "udp",
    "Carbon line-in"
  ],
  "carbon-pickle-tcp": [
    2013,
    2013,
    "tcp",
    "Carbon pickle"
  ],
  "carbon-pickle-udp": [
    2013,
    2013,
    "udp",
    "Carbon pickle"
  ],
  "cassandra-clients-tcp": [
    9042,
    9042,
    "tcp",
    "Cassandra clients"
  ],
  "cassandra-jmx-tcp": [
    7199,
    7199,
    "tcp",
    "JMX"
  ],
  "cassandra-thrift-clients-tcp": [
    9160,
    9160,
    "tcp",
    "Cassandra Thrift clients"
  ],
  "consul-dns-tcp": [
    8600,
    8600,
    "tcp",
    "Consul DNS"
  ],
  "consul-dns-udp": [
    8600,
    8600,
    "udp",
    "Consul DNS"
  ],
  "consul-grpc-tcp": [
    8502,
    8502,
    "tcp",
    "Consul gRPC"
  ],
  "consul-grpc-tcp-tls": [
    8503,
    8503,
    "tcp",
    "Consul gRPC TLS"
  ],
  "consul-serf-lan-tcp": [
    8301,
    8301,
    "tcp",
    "Serf LAN"
  ],
  "consul-serf-lan-udp": [
    8301,
    8301,
    "udp",
    "Serf LAN"
  ],
  "consul-serf-wan-tcp": [
    8302,
    8302,
    "tcp",
    "Serf WAN"
  ],
  "consul-serf-wan-udp": [
    8302,
    8302,
    "udp",
    "Serf WAN"
  ],
  "consul-tcp": [
    8300,
    8300,
    "tcp",
    "Consul server"
  ],
  "consul-webui-http-tcp": [
    8500,
    8500,
    "tcp",
    "Consul web UI HTTP"
  ],
  "consul-webui-https-tcp": [
    8501,
    8501,
    "tcp",
    "Consul web UI HTTPS"
  ],
  "dax-cluster-encrypted-tcp": [
    9111,
    9111,
    "tcp",
    "DAX Cluster encrypted"
  ],
  "dax-cluster-unencrypted-tcp": [
    8111,
    8111,
    "tcp",
    "DAX Cluster unencrypted"
  ],
  "dns-tcp": [
    53,
    53,
    "tcp",
    "DNS"
  ],
  "dns-udp": [
    53,
    53,
    "udp",
    "DNS"
  ],
  "docker-swarm-mngmt-tcp": [
    2377,
    2377,
    "tcp",
    "Docker Swarm cluster management"
  ],
  "docker-swarm-node-tcp": [
    7946,
    7946,
    "tcp",
    "Docker Swarm node"
  ],
  "docker-swarm-node-udp": [
    7946,
    7946,
    "udp",
    "Docker Swarm node"
  ],
  "docker-swarm-overlay-udp": [
    4789,
    4789,
    "udp",
    "Docker Swarm Overlay Network Traffic"
  ],
  "elasticsearch-java-tcp": [
    9300,
    9300,
    "tcp",
    "Elasticsearch Java interface"
  ],
  "elasticsearch-rest-tcp": [
    9200,
    9200,
    "tcp",
    "Elasticsearch REST interface"
  ],
  "etcd-client-tcp": [
    2379,
    2379,
    "tcp",
    "Etcd Client"
  ],
  "etcd-peer-tcp": [
    2380,
    2380,
    "tcp",
    "Etcd Peer"
  ],
  "grafana-tcp": [
    3000,
    3000,
    "tcp",
    "Grafana Dashboard"
  ],
  "graphite-2003-tcp": [
    2003,
    2003,
    "tcp",
    "Carbon receiver plain text"
  ],
  "graphite-2004-tcp": [
    2004,
    2004,
    "tcp",
    "Carbon receiver pickle"
  ],
  "graphite-2023-tcp": [
    2023,
    2023,
    "tcp",
    "Carbon aggregator plaintext"
  ],
  "graphite-2024-tcp": [
    2024,
    2024,
    "tcp",
    "Carbon aggregator pickle"
  ],
  "graphite-8080-tcp": [
    8080,
    8080,
    "tcp",
    "Graphite gunicorn port"
  ],
  "graphite-8125-tcp": [
    8125,
    8125,
    "tcp",
    "Statsd TCP"
  ],
  "graphite-8125-udp": [
    8125,
    8125,
    "udp",
    "Statsd UDP default"
  ],
  "graphite-8126-tcp": [
    8126,
    8126,
    "tcp",
    "Statsd admin"
  ],
  "graphite-webui": [
    80,
    80,
    "tcp",
    "Graphite admin interface"
  ],
  "http-80-tcp": [
    80,
    80,
    "tcp",
    "HTTP"
  ],
  "http-8080-tcp": [
    8080,
    8080,
    "tcp",
    "HTTP"
  ],
  "https-443-tcp": [
    443,
    443,
    "tcp",
    "HTTPS"
  ],
  "https-8443-tcp": [
    8443,
    8443,
    "tcp",
    "HTTPS"
  ],
  "ipsec-4500-udp": [
    4500,
    4500,
    "udp",
    "IPSEC NAT-T"
  ],
  "ipsec-500-udp": [
    500,
    500,
    "udp",
    "IPSEC ISAKMP"
  ],
  "kafka-broker-sasl-iam-public-tcp": [
    9198,
    9198,
    "tcp",
    "Kafka SASL/IAM Public access control enabled (MSK specific)"
  ],
  "kafka-broker-sasl-iam-tcp": [
    9098,
    9098,
    "tcp",
    "Kafka SASL/IAM access control enabled (MSK specific)"
  ],
  "kafka-broker-sasl-scram-public-tcp": [
    9196,
    9196,
    "tcp",
    "Kafka SASL/SCRAM Public enabled broker (MSK specific)"
  ],
  "kafka-broker-sasl-scram-tcp": [
    9096,
    9096,
    "tcp",
    "Kafka SASL/SCRAM enabled broker (MSK specific)"
  ],
  "kafka-broker-tcp": [
    9092,
    9092,
    "tcp",
    "Kafka PLAINTEXT enable broker 0.8.2+"
  ],
  "kafka-broker-tls-public-tcp": [
    9194,
    9194,
    "tcp",
    "Kafka TLS Public enabled broker 0.8.2+ (MSK specific)"
  ],
  "kafka-broker-tls-tcp": [
    9094,
    9094,
    "tcp",
    "Kafka TLS enabled broker 0.8.2+"
  ],
  "kafka-jmx-exporter-tcp": [
    11001,
    11001,
    "tcp",
    "Kafka JMX Exporter"
  ],
  "kafka-node-exporter-tcp": [
    11002,
    11002,
    "tcp",
    "Kafka Node Exporter"
  ],
  "kibana-tcp": [
    5601,
    5601,
    "tcp",
    "Kibana Web Interface"
  ],
  "kubernetes-api-tcp": [
    6443,
    6443,
    "tcp",
    "Kubernetes API Server"
  ],
  "ldap-tcp": [
    389,
    389,
    "tcp",
    "LDAP"
  ],
  "ldaps-tcp": [
    636,
    636,
    "tcp",
    "LDAPS"
  ],
  "logstash-tcp": [
    5044,
    5044,
    "tcp",
    "Logstash"
  ],
  "loki-grafana": [
    3100,
    3100,
    "tcp",
    "Grafana Loki endpoint"
  ],
  "loki-grafana-grpc": [
    9095,
    9095,
    "tcp",
    "Grafana Loki GRPC"
  ],
  "memcached-tcp": [
    11211,
    11211,
    "tcp",
    "Memcached"
  ],
  "minio-tcp": [
    9000,
    9000,
    "tcp",
    "MinIO"
  ],
  "mongodb-27017-tcp": [
    27017,
    27017,
    "tcp",
    "MongoDB"
  ],
  "mongodb-27018-tcp": [
    27018,
    27018,
    "tcp",
    "MongoDB shard"
  ],
  "mongodb-27019-tcp": [
    27019,
    27019,
    "tcp",
    "MongoDB config server"
  ],
  "mssql-analytics-tcp": [
    2383,
    2383,
    "tcp",
    "MSSQL Analytics"
  ],
  "mssql-broker-tcp": [
    4022,
    4022,
    "tcp",
    "MSSQL Broker"
  ],
  "mssql-tcp": [
    1433,
    1433,
    "tcp",
    "MSSQL Server"
  ],
  "mssql-udp": [
    1434,
    1434,
    "udp",
    "MSSQL Browser"
  ],
  "mysql-tcp": [
    3306,
    3306,
    "tcp",
    "MySQL/Aurora"
  ],
  "nfs-tcp": [
    2049,
    2049,
    "tcp",
    "NFS/EFS"
  ],
  "nomad-http-tcp": [
    4646,
    4646,
    "tcp",
    "Nomad HTTP"
  ],
  "nomad-rpc-tcp": [
    4647,
    4647,
    "tcp",
    "Nomad RPC"
  ],
  "nomad-serf-tcp": [
    4648,
    4648,
    "tcp",
    "Serf"
  ],
  "nomad-serf-udp": [
    4648,
    4648,
    "udp",
    "Serf"
  ],
  "ntp-udp": [
    123,
    123,
    "udp",
    "NTP"
  ],
  "octopus-tentacle-tcp": [
    10933,
    10933,
    "tcp",
    "Octopus Tentacle"
  ],
  "openvpn-https-tcp": [
    443,
    443,
    "tcp",
    "OpenVPN"
  ],
  "openvpn-tcp": [
    943,
    943,
    "tcp",
    "OpenVPN"
  ],
  "openvpn-udp": [
    1194,
    1194,
    "udp",
    "OpenVPN"
  ],
  "oracle-db-tcp": [
    1521,
    1521,
    "tcp",
    "Oracle"
  ],
  "postgresql-tcp": [
    5432,
    5432,
    "tcp",
    "PostgreSQL"
  ],
  "prometheus-http-tcp": [
    9090,
    9090,
    "tcp",
    "Prometheus"
  ],
  "prometheus-node-exporter-http-tcp": [
    9100,
    9100,
    "tcp",
    "Prometheus Node Exporter"
  ],
  "prometheus-pushgateway-http-tcp": [
    9091,
    9091,
    "tcp",
    "Prometheus Pushgateway"
  ],
  "promtail-http": [
    9080,
    9080,
    "tcp",
    "Promtail endpoint"
  ],
  "puppet-tcp": [
    8140,
    8140,
    "tcp",
    "Puppet"
  ],
  "puppetdb-tcp": [
    8081,
    8081,
    "tcp",
    "PuppetDB"
  ],
  "rabbitmq-15672-tcp": [
    15672,
    15672,
    "tcp",
    "RabbitMQ"
  ],
  "rabbitmq-25672-tcp": [
    25672,
    25672,
    "tcp",
    "RabbitMQ"
  ],
  "rabbitmq-4369-tcp": [
    4369,
    4369,
    "tcp",
    "RabbitMQ epmd"
  ],
  "rabbitmq-5671-tcp": [
    5671,
    5671,
    "tcp",
    "RabbitMQ"
  ],
  "rabbitmq-5672-tcp": [
    5672,
    5672,
    "tcp",
    "RabbitMQ"
  ],
  "rdp-tcp": [
    3389,
    3389,
    "tcp",
    "Remote Desktop"
  ],
  "rdp-udp": [
    3389,
    3389,
    "udp",
    "Remote Desktop"
  ],
  "redis-tcp": [
    6379,
    6379,
    "tcp",
    "Redis"
  ],
  "redshift-tcp": [
    5439,
    5439,
    "tcp",
    "Redshift"
  ],
  "saltstack-tcp": [
    4505,
    4506,
    "tcp",
    "SaltStack"
  ],
  "smtp-submission-2587-tcp": [
    2587,
    2587,
    "tcp",
    "SMTP Submission"
  ],
  "smtp-submission-587-tcp": [
    587,
    587,
    "tcp",
    "SMTP Submission"
  ],
  "smtp-tcp": [
    25,
    25,
    "tcp",
    "SMTP"
  ],
  "smtps-2456-tcp": [
    2465,
    2465,
    "tcp",
    "SMTPS"
  ],
  "smtps-465-tcp": [
    465,
    465,
    "tcp",
    "SMTPS"
  ],
  "solr-tcp": [
    8983,
    8987,
    "tcp",
    "Solr"
  ],
  "splunk-hec-tcp": [
    8088,
    8088,
    "tcp",
    "Splunk HEC"
  ],
  "splunk-indexer-tcp": [
    9997,
    9997,
    "tcp",
    "Splunk indexer"
  ],
  "splunk-splunkd-tcp": [
    8089,
    8089,
    "tcp",
    "Splunkd"
  ],
  "splunk-web-tcp": [
    8000,
    8000,
    "tcp",
    "Splunk Web"
  ],
  "squid-proxy-tcp": [
    3128,
    3128,
    "tcp",
    "Squid default proxy"
  ],
  "ssh-tcp": [
    22,
    22,
    "tcp",
    "SSH"
  ],
  "storm-nimbus-tcp": [
    6627,
    6627,
    "tcp",
    "Nimbus"
  ],
  "storm-supervisor-tcp": [
    6700,
    6703,
    "tcp",
    "Supervisor"
  ],
  "storm-ui-tcp": [
    8080,
    8080,
    "tcp",
    "Storm UI"
  ],
  "vault-tcp": [
    8200,
    8200,
    "tcp",
    "Vault"
  ],
  "wazuh-dashboard": [
    443,
    443,
    "tcp",
    "Wazuh web user interface"
  ],
  "wazuh-indexer-restful-api": [
    9200,
    9200,
    "tcp",
    "Wazuh indexer RESTful API"
  ],
  "wazuh-server-agent-cluster-daemon": [
    1516,
    1516,
    "tcp",
    "Wazuh cluster daemon"
  ],
  "wazuh-server-agent-connection-tcp": [
    1514,
    1514,
    "tcp",
    "Agent connection service(TCP)"
  ],
  "wazuh-server-agent-connection-udp": [
    1514,
    1514,
    "udp",
    "Agent connection service(UDP)"
  ],
  "wazuh-server-agent-enrollment": [
    1515,
    1515,
    "tcp",
    "Agent enrollment service"
  ],
  "wazuh-server-restful-api": [
    55000,
    55000,
    "tcp",
    "Wazuh server RESTful API"
  ],
  "wazuh-server-syslog-collector-tcp": [
    514,
    514,
    "tcp",
    "Wazuh Syslog collector(TCP)"
  ],
  "wazuh-server-syslog-collector-udp": [
    514,
    514,
    "udp",
    "Wazuh Syslog collector(UDP)"
  ],
  "web-jmx-tcp": [
    1099,
    1099,
    "tcp",
    "JMX"
  ],
  "winrm-http-tcp": [
    5985,
    5985,
    "tcp",
    "WinRM HTTP"
  ],
  "winrm-https-tcp": [
    5986,
    5986,
    "tcp",
    "WinRM HTTPS"
  ],
  "zabbix-agent": [
    10050,
    10050,
    "tcp",
    "Zabbix Agent"
  ],
  "zabbix-proxy": [
    10051,
    10051,
    "tcp",
    "Zabbix Proxy"
  ],
  "zabbix-server": [
    10051,
    10051,
    "tcp",
    "Zabbix Server"
  ],
  "zipkin-admin-query-tcp": [
    9901,
    9901,
    "tcp",
    "Zipkin Admin port query"
  ],
  "zipkin-admin-tcp": [
    9990,
    9990,
    "tcp",
    "Zipkin Admin port collector"
  ],
  "zipkin-admin-web-tcp": [
    9991,
    9991,
    "tcp",
    "Zipkin Admin port web"
  ],
  "zipkin-query-tcp": [
    9411,
    9411,
    "tcp",
    "Zipkin query port"
  ],
  "zipkin-web-tcp": [
    8080,
    8080,
    "tcp",
    "Zipkin web port"
  ],
  "zookeeper-2181-tcp": [
    2181,
    2181,
    "tcp",
    "Zookeeper"
  ],
  "zookeeper-2182-tls-tcp": [
    2182,
    2182,
    "tcp",
    "Zookeeper TLS (MSK specific)"
  ],
  "zookeeper-2888-tcp": [
    2888,
    2888,
    "tcp",
    "Zookeeper"
  ],
  "zookeeper-3888-tcp": [
    3888,
    3888,
    "tcp",
    "Zookeeper"
  ],
  "zookeeper-jmx-tcp": [
    7199,
    7199,
    "tcp",
    "JMX"
  ]
}
```

### <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id)

Description: ID of existing security group whose rules we will manage

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: A mapping of tags to assign to security group

Type: `map(string)`

Default: `{}`

### <a name="input_use_name_prefix"></a> [use\_name\_prefix](#input\_use\_name\_prefix)

Description: Whether to use name\_prefix or fixed name. Should be true to able to update security group name after initial creation

Type: `bool`

Default: `true`

### <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id)

Description: ID of the VPC where to create security group

Type: `string`

Default: `null`

## Resources

The following resources are used by this module:

- [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) (resource)
- [aws_security_group.main_name_prefix](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) (resource)
- [aws_security_group_rule.computed_egress_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.computed_egress_with_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.computed_egress_with_ipv6_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.computed_egress_with_prefix_list_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.computed_egress_with_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.computed_egress_with_source_security_group_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.computed_ingress_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.computed_ingress_with_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.computed_ingress_with_ipv6_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.computed_ingress_with_prefix_list_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.computed_ingress_with_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.computed_ingress_with_source_security_group_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.egress_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.egress_with_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.egress_with_ipv6_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.egress_with_prefix_list_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.egress_with_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.egress_with_source_security_group_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.ingress_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.ingress_with_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.ingress_with_ipv6_cidr_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.ingress_with_prefix_list_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.ingress_with_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)
- [aws_security_group_rule.ingress_with_source_security_group_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) (resource)

## Outputs

The following outputs are exported:

### <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn)

Description: The ARN of the security group

### <a name="output_security_group_description"></a> [security\_group\_description](#output\_security\_group\_description)

Description: The description of the security group

### <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id)

Description: The ID of the security group

### <a name="output_security_group_name"></a> [security\_group\_name](#output\_security\_group\_name)

Description: The name of the security group

### <a name="output_security_group_owner_id"></a> [security\_group\_owner\_id](#output\_security\_group\_owner\_id)

Description: The owner ID

### <a name="output_security_group_vpc_id"></a> [security\_group\_vpc\_id](#output\_security\_group\_vpc\_id)

Description: The VPC ID

<!-- markdownlint-enable -->
<!-- END_TF_DOCS -->