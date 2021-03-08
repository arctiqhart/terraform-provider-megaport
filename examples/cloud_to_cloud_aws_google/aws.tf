/**
 * Copyright 2020 Megaport Pty Ltd
 *
 * Licensed under the Mozilla Public License, Version 2.0 (the
 * "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *       https://mozilla.org/MPL/2.0/
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

data "aws_caller_identity" "current" {}

data "aws_ami" "amzn2linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

// networking
resource "aws_vpc" "megaport_poc" {
  cidr_block = var.aws_vpc_cidr

  tags = {
    Name = "${var.prefix} Terraform VPC"
  }
}

resource "aws_subnet" "megaport_poc" {
  vpc_id                  = aws_vpc.megaport_poc.id
  cidr_block              = aws_vpc.megaport_poc.cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.prefix} Terraform Subnet"
  }
}

resource "aws_route_table" "megaport_poc" {
  vpc_id = aws_vpc.megaport_poc.id

  tags = {
    Name = "${var.prefix} Terraform Route Table"
  }
}

resource "aws_route_table_association" "megaport_poc" {
  subnet_id      = aws_subnet.megaport_poc.id
  route_table_id = aws_route_table.megaport_poc.id
}

resource "aws_security_group" "megaport_poc" {
  vpc_id      = aws_vpc.megaport_poc.id
  name        = "${var.prefix} Terraform Security Group"
  description = "${var.prefix} Terraform Security Group"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.prefix} Terraform Security Group"
    Description = "${var.prefix} Terraform Security Group"
  }
}

// vpn gateway
resource "aws_vpn_gateway" "megaport_poc" {
  vpc_id = aws_vpc.megaport_poc.id

  tags = {
    Name = "${var.prefix} Terraform Virtual Gateway"
  }
}

resource "aws_vpn_gateway_route_propagation" "megaport_poc" {
  vpn_gateway_id = aws_vpn_gateway.megaport_poc.id
  route_table_id = aws_route_table.megaport_poc.id
}

// direct connect
resource "aws_dx_gateway" "megaport_poc" {
  name            = "${var.prefix} Terraform DX Gateway"
  amazon_side_asn = var.aws_dx_gateway_asn
}

resource "aws_dx_gateway_association" "megaport_poc" {
  dx_gateway_id         = aws_dx_gateway.megaport_poc.id
  associated_gateway_id = aws_vpn_gateway.megaport_poc.id
}

resource "aws_dx_hosted_private_virtual_interface_accepter" "megaport_poc" {
  virtual_interface_id = megaport_aws_connection.example.aws_id
  vpn_gateway_id       = aws_vpn_gateway.megaport_poc.id

  tags = {
    Side = "Accepter"
    Name = "${var.prefix} Accepter"
  }
}

// instance
resource "aws_instance" "megaport_poc" {
  ami                    = data.aws_ami.amzn2linux.id
  instance_type          = var.aws_ec2_instance_type
  subnet_id              = aws_subnet.megaport_poc.id
  vpc_security_group_ids = [aws_security_group.megaport_poc.id]
  key_name               = var.aws_ec2_key_pair_name

  tags = {
    Name = "${var.prefix} Terraform Instance"
  }
}
