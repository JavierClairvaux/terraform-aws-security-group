# AWS EC2-VPC Security Group Terraform module

[![Help Contribute to Open Source](https://www.codetriage.com/terraform-aws-modules/terraform-aws-security-group/badges/users.svg)](https://www.codetriage.com/terraform-aws-modules/terraform-aws-security-group)

Terraform module which creates [EC2 security group within VPC](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_SecurityGroups.html) on AWS.

These types of resources are supported:

* [EC2-VPC Security Group](https://www.terraform.io/docs/providers/aws/r/security_group.html)
* [EC2-VPC Security Group Rule](https://www.terraform.io/docs/providers/aws/r/security_group_rule.html)

## Features

This module aims to implement **ALL** combinations of arguments supported by AWS and latest stable version of Terraform:
* IPv4/IPv6 CIDR blocks
* [VPC endpoint prefix lists](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-endpoints.html) (use data source [aws_prefix_list](https://www.terraform.io/docs/providers/aws/d/prefix_list.html))
* Access from source security groups
* Access from self
* Named rules ([see the rules here](https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf))
* Named groups of rules with ingress (inbound) and egress (outbound) ports open for common scenarios (eg, [ssh](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/modules/ssh), [http-80](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/modules/http-80), [mysql](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/modules/mysql), see the whole list [here](https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/modules/README.md))
* Conditionally create security group and all required security group rules ("single boolean switch").

Ingress and egress rules can be configured in a variety of ways. See [inputs section](#inputs) for all supported arguments and [complete example](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/examples/complete) for the complete use-case.

If there is a missing feature or a bug - [open an issue](https://github.com/terraform-aws-modules/terraform-aws-security-group/issues/new).

## Terraform versions

For Terraform 0.12 use version `v3.*` of this module.

If you are using Terraform 0.11 you can use versions `v2.*`.

## Usage

There are two ways to create security groups using this module:

1. [Specifying predefined rules (HTTP, SSH, etc)](https://github.com/terraform-aws-modules/terraform-aws-security-group#security-group-with-predefined-rules)
1. [Specifying custom rules](https://github.com/terraform-aws-modules/terraform-aws-security-group#security-group-with-custom-rules)

### Security group with predefined rules

```hcl
module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "web-server"
  description = "Security group for web-server with HTTP ports open within VPC"
  vpc_id      = "vpc-12345678"

  ingress_cidr_blocks = ["10.10.0.0/16"]
}
```

### Security group with custom rules

```hcl
module "vote_service_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "user-service"
  description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
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
}
```

### Note about "value of 'count' cannot be computed"

Terraform 0.11 has a limitation which does not allow **computed** values inside `count` attribute on resources (issues: [#16712](https://github.com/hashicorp/terraform/issues/16712), [#18015](https://github.com/hashicorp/terraform/issues/18015), ...)

Computed values are values provided as outputs from `module`. Non-computed values are all others - static values, values referenced as `variable` and from data-sources.

When you need to specify computed value inside security group rule argument you need to specify it using an argument which starts with `computed_` and provide a number of elements in the argument which starts with `number_of_computed_`. See these examples:

```hcl
module "http_sg" {
  source = "terraform-aws-modules/security-group/aws"
  # omitted for brevity
}

module "db_computed_source_sg" {
  # omitted for brevity

  vpc_id = "vpc-12345678" # these are valid values also - "${module.vpc.vpc_id}" and "${local.vpc_id}"

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = "${module.http_sg.this_security_group_id}"
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
}

module "db_computed_sg" {
  # omitted for brevity

  ingress_cidr_blocks = ["10.10.0.0/16", "${data.aws_security_group.default.id}"]

  computed_ingress_cidr_blocks = ["${module.vpc.vpc_cidr_block}"]
  number_of_computed_ingress_cidr_blocks = 1
}

module "db_computed_merged_sg" {
  # omitted for brevity

  computed_ingress_cidr_blocks = ["10.10.0.0/16", "${module.vpc.vpc_cidr_block}"]
  number_of_computed_ingress_cidr_blocks = 2
}
```

Note that `db_computed_sg` and `db_computed_merged_sg` are equal, because it is possible to put both computed and non-computed values in arguments starting with `computed_`.

## Conditional creation

Sometimes you need to have a way to create security group conditionally but Terraform does not allow to use `count` inside `module` block, so the solution is to specify argument `create`.

```hcl
# This security group will not be created
module "vote_service_sg" {
  source = "terraform-aws-modules/security-group/aws"

  create = false
  # ... omitted
}
```

## Examples

* [Complete Security Group example](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/examples/complete) shows all available parameters to configure security group.
* [HTTP Security Group example](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/examples/http) shows more applicable security groups for common web-servers.
* [Disable creation of Security Group example](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/examples/disabled) shows how to disable creation of security group.
* [Dynamic values inside Security Group rules example](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/examples/dynamic) shows how to specify values inside security group rules (data-sources and variables are allowed).
* [Computed values inside Security Group rules example](https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/examples/computed) shows how to specify computed values inside security group rules (solution for `value of 'count' cannot be computed` problem).

## How to add/update rules/groups?

Rules and groups are defined in [rules.tf](https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf). Run `update_groups.sh` when content of that file has changed to recreate content of all automatic modules.

## Known issues

No issue is creating limit on this module.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.6, < 0.14 |
| aws | >= 2.42, < 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.42, < 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| auto\_groups | Map of groups of security group rules to use to generate modules (see update\_groups.sh) | `map(map(list(string)))` | <pre>{<br>  "http-80": {<br>    "egress_rules": [<br>      "all-all"<br>    ],<br>    "ingress_rules": [<br>      "http-80-tcp"<br>    ],<br>    "ingress_with_self": [<br>      "all-all"<br>    ]<br>  },<br>  "https-443": {<br>    "egress_rules": [<br>      "all-all"<br>    ],<br>    "ingress_rules": [<br>      "https-443-tcp"<br>    ],<br>    "ingress_with_self": [<br>      "all-all"<br>    ]<br>  },<br>  "ssh": {<br>    "egress_rules": [<br>      "all-all"<br>    ],<br>    "ingress_rules": [<br>      "ssh-tcp"<br>    ],<br>    "ingress_with_self": [<br>      "all-all"<br>    ]<br>  }<br>}</pre> | no |
| computed\_egress\_rules | List of computed egress rules to create by name | `list(string)` | `[]` | no |
| computed\_egress\_with\_cidr\_blocks | List of computed egress rules to create where 'cidr\_blocks' is used | `list(map(string))` | `[]` | no |
| computed\_egress\_with\_ipv6\_cidr\_blocks | List of computed egress rules to create where 'ipv6\_cidr\_blocks' is used | `list(map(string))` | `[]` | no |
| computed\_egress\_with\_self | List of computed egress rules to create where 'self' is defined | `list(map(string))` | `[]` | no |
| computed\_egress\_with\_source\_security\_group\_id | List of computed egress rules to create where 'source\_security\_group\_id' is used | `list(map(string))` | `[]` | no |
| computed\_ingress\_rules | List of computed ingress rules to create by name | `list(string)` | `[]` | no |
| computed\_ingress\_with\_cidr\_blocks | List of computed ingress rules to create where 'cidr\_blocks' is used | `list(map(string))` | `[]` | no |
| computed\_ingress\_with\_ipv6\_cidr\_blocks | List of computed ingress rules to create where 'ipv6\_cidr\_blocks' is used | `list(map(string))` | `[]` | no |
| computed\_ingress\_with\_self | List of computed ingress rules to create where 'self' is defined | `list(map(string))` | `[]` | no |
| computed\_ingress\_with\_source\_security\_group\_id | List of computed ingress rules to create where 'source\_security\_group\_id' is used | `list(map(string))` | `[]` | no |
| create | Whether to create security group and all rules | `bool` | `true` | no |
| description | Description of security group | `string` | `"Security Group managed by Terraform"` | no |
| egress\_cidr\_blocks | List of IPv4 CIDR ranges to use on all egress rules | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| egress\_ipv6\_cidr\_blocks | List of IPv6 CIDR ranges to use on all egress rules | `list(string)` | <pre>[<br>  "::/0"<br>]</pre> | no |
| egress\_prefix\_list\_ids | List of prefix list IDs (for allowing access to VPC endpoints) to use on all egress rules | `list(string)` | `[]` | no |
| egress\_rules | List of egress rules to create by name | `list(string)` | `[]` | no |
| egress\_with\_cidr\_blocks | List of egress rules to create where 'cidr\_blocks' is used | `list(map(string))` | `[]` | no |
| egress\_with\_ipv6\_cidr\_blocks | List of egress rules to create where 'ipv6\_cidr\_blocks' is used | `list(map(string))` | `[]` | no |
| egress\_with\_self | List of egress rules to create where 'self' is defined | `list(map(string))` | `[]` | no |
| egress\_with\_source\_security\_group\_id | List of egress rules to create where 'source\_security\_group\_id' is used | `list(map(string))` | `[]` | no |
| ingress\_cidr\_blocks | List of IPv4 CIDR ranges to use on all ingress rules | `list(string)` | `[]` | no |
| ingress\_ipv6\_cidr\_blocks | List of IPv6 CIDR ranges to use on all ingress rules | `list(string)` | `[]` | no |
| ingress\_prefix\_list\_ids | List of prefix list IDs (for allowing access to VPC endpoints) to use on all ingress rules | `list(string)` | `[]` | no |
| ingress\_rules | List of ingress rules to create by name | `list(string)` | `[]` | no |
| ingress\_with\_cidr\_blocks | List of ingress rules to create where 'cidr\_blocks' is used | `list(map(string))` | `[]` | no |
| ingress\_with\_ipv6\_cidr\_blocks | List of ingress rules to create where 'ipv6\_cidr\_blocks' is used | `list(map(string))` | `[]` | no |
| ingress\_with\_self | List of ingress rules to create where 'self' is defined | `list(map(string))` | `[]` | no |
| ingress\_with\_source\_security\_group\_id | List of ingress rules to create where 'source\_security\_group\_id' is used | `list(map(string))` | `[]` | no |
| name | Name of security group | `string` | n/a | yes |
| number\_of\_computed\_egress\_rules | Number of computed egress rules to create by name | `number` | `0` | no |
| number\_of\_computed\_egress\_with\_cidr\_blocks | Number of computed egress rules to create where 'cidr\_blocks' is used | `number` | `0` | no |
| number\_of\_computed\_egress\_with\_ipv6\_cidr\_blocks | Number of computed egress rules to create where 'ipv6\_cidr\_blocks' is used | `number` | `0` | no |
| number\_of\_computed\_egress\_with\_self | Number of computed egress rules to create where 'self' is defined | `number` | `0` | no |
| number\_of\_computed\_egress\_with\_source\_security\_group\_id | Number of computed egress rules to create where 'source\_security\_group\_id' is used | `number` | `0` | no |
| number\_of\_computed\_ingress\_rules | Number of computed ingress rules to create by name | `number` | `0` | no |
| number\_of\_computed\_ingress\_with\_cidr\_blocks | Number of computed ingress rules to create where 'cidr\_blocks' is used | `number` | `0` | no |
| number\_of\_computed\_ingress\_with\_ipv6\_cidr\_blocks | Number of computed ingress rules to create where 'ipv6\_cidr\_blocks' is used | `number` | `0` | no |
| number\_of\_computed\_ingress\_with\_self | Number of computed ingress rules to create where 'self' is defined | `number` | `0` | no |
| number\_of\_computed\_ingress\_with\_source\_security\_group\_id | Number of computed ingress rules to create where 'source\_security\_group\_id' is used | `number` | `0` | no |
| revoke\_rules\_on\_delete | Instruct Terraform to revoke all of the Security Groups attached ingress and egress rules before deleting the rule itself. Enable for EMR. | `bool` | `false` | no |
| rules | Map of known security group rules (define as 'name' = ['from port', 'to port', 'protocol', 'description']) | `map(list(any))` | <pre>{<br>  "_": [<br>    "",<br>    "",<br>    ""<br>  ],<br>  "http-80-tcp": [<br>    80,<br>    80,<br>    "tcp",<br>    "HTTP"<br>  ],<br>  "https-443-tcp": [<br>    443,<br>    443,<br>    "tcp",<br>    "HTTPS"<br>  ],<br>  "ssh-tcp": [<br>    22,<br>    22,<br>    "tcp",<br>    "SSH"<br>  ]<br>}</pre> | no |
| tags | A mapping of tags to assign to security group | `map(string)` | `{}` | no |
| use\_name\_prefix | Whether to use name\_prefix or fixed name. Should be true to able to update security group name after initial creation | `bool` | `true` | no |
| vpc\_id | ID of the VPC where to create security group | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| this\_security\_group\_description | The description of the security group |
| this\_security\_group\_id | The ID of the security group |
| this\_security\_group\_name | The name of the security group |
| this\_security\_group\_owner\_id | The owner ID |
| this\_security\_group\_vpc\_id | The VPC ID |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module managed by [Anton Babenko](https://github.com/antonbabenko).

## License

Apache 2 Licensed. See LICENSE for full details.
