provider "aws" {
  region = "us-east-2"
}

#############################################################
# Data sources to get VPC and default security group details
#############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

###########################
# Security groups examples
###########################

#######
# HTTP
#######

module "http_sg" {
  source = "../../"

  name        = "http-sg"
  description = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = data.aws_vpc.default.id

  ingress_rules = ["https-443-tcp", "ssh-tcp"]

  ingress_cidr_blocks = ["10.1.0.0/16", "10.2.0.0/16"]
}

module "user_service" {
  source = "../../"

  name        = "user-service"
  description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["10.10.0.0/16"]
  ingress_rules       = ["https-443-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8090
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "10.10.0.0/16"
    },
    {
      rule        = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
