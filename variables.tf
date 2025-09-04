variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "suse-ai-aws"
}

variable "public_key" {
  description = "Public key for SSH access to instances"
  type        = string
  validation {
    condition     = length(var.public_key) > 0
    error_message = "Public key must not be empty."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "rancher_server_count" {
  description = "Number of Rancher server instances (c6i.xlarge with 150GB storage)"
  type        = number
  default     = 1
  validation {
    condition     = var.rancher_server_count >= 0 && var.rancher_server_count <= 5
    error_message = "Rancher server count must be between 0 and 5."
  }
}

variable "gpu_instance_count" {
  description = "Number of GPU instances (g4dn.xlarge with 200GB storage)"
  type        = number
  default     = 1
  validation {
    condition     = var.gpu_instance_count >= 0 && var.gpu_instance_count <= 10
    error_message = "GPU instance count must be between 0 and 10."
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for instances"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}