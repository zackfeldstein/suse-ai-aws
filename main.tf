terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Using specific SUSE Linux Enterprise Server 15 SP7 AMI for both instances
locals {
  suse_ami_id = "ami-052cee36f31273da3" # SUSE Linux Enterprise Server 15 SP7
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-igw"
  })
}

# Create public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-public-subnet"
  })
}

# Create route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

# Associate route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for Rancher Server (VM Type 1)
resource "aws_security_group" "rancher_sg" {
  name_prefix = "${var.project_name}-rancher-"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Rancher UI (default port)
  ingress {
    description = "Rancher UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Rancher UI (HTTPS)
  ingress {
    description = "Rancher UI HTTPS"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-rancher-sg"
  })
}

# Security Group for GPU instances (VM Type 2)
resource "aws_security_group" "gpu_sg" {
  name_prefix = "${var.project_name}-gpu-"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jupyter/ML services common ports
  ingress {
    description = "Jupyter/ML Services"
    from_port   = 8888
    to_port     = 8892
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-gpu-sg"
  })
}

# Key pair for SSH access
resource "aws_key_pair" "vm_key" {
  key_name   = "${var.project_name}-key"
  public_key = var.public_key
}

# Rancher Server instances - c6i.xlarge with 150GB storage (SUSE Linux)
resource "aws_instance" "rancher_server" {
  count                  = var.rancher_server_count
  ami                    = local.suse_ami_id
  instance_type          = "c6i.xlarge"
  key_name               = aws_key_pair.vm_key.key_name
  vpc_security_group_ids = [aws_security_group.rancher_sg.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_type = "gp3"
    volume_size = 150
    encrypted   = true
    tags = merge(var.additional_tags, {
      Name = "${var.project_name}-rancher-${count.index + 1}-root"
    })
  }

  user_data = <<-EOF
              #!/bin/bash
              # Basic setup - detailed configuration will be handled by Ansible
              echo "Instance ready for Ansible configuration at $(date)" > /tmp/instance-ready
              EOF

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-rancher-${count.index + 1}"
    Type = "rancher-server"
    Role = "container-orchestration"
    OS   = "suse-linux-15-sp7"
  })
}

# GPU instances - g4dn.xlarge with 200GB storage (SUSE Linux)
resource "aws_instance" "gpu_instance" {
  count                  = var.gpu_instance_count
  ami                    = local.suse_ami_id
  instance_type          = "g4dn.xlarge"
  key_name               = aws_key_pair.vm_key.key_name
  vpc_security_group_ids = [aws_security_group.gpu_sg.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_type = "gp3"
    volume_size = 200
    encrypted   = true
    tags = merge(var.additional_tags, {
      Name = "${var.project_name}-gpu-${count.index + 1}-root"
    })
  }

  user_data = <<-EOF
              #!/bin/bash
              # Basic setup - detailed configuration will be handled by Ansible
              echo "Instance ready for Ansible configuration at $(date)" > /tmp/instance-ready
              EOF

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-gpu-${count.index + 1}"
    Type = "gpu-instance"
    Role = "ml-compute"
    OS   = "suse-linux-15-sp7"
  })
}