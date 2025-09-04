output "vpc_info" {
  description = "VPC and networking information"
  value = {
    vpc_id            = aws_vpc.main.id
    vpc_cidr          = aws_vpc.main.cidr_block
    public_subnet_id  = aws_subnet.public.id
    public_subnet_cidr = aws_subnet.public.cidr_block
    internet_gateway_id = aws_internet_gateway.main.id
  }
}

output "rancher_servers" {
  description = "Information about Rancher server instances (c6i.xlarge with 150GB storage on SUSE Linux)"
  value = {
    count         = length(aws_instance.rancher_server)
    instance_type = "c6i.xlarge"
    operating_system = "SUSE Linux Enterprise Server 15 SP7"
    ami_id        = local.suse_ami_id
    storage_size  = "150GB"
    instance_ids  = aws_instance.rancher_server[*].id
    public_ips    = aws_instance.rancher_server[*].public_ip
    private_ips   = aws_instance.rancher_server[*].private_ip
    public_dns    = aws_instance.rancher_server[*].public_dns
  }
}

output "gpu_instances" {
  description = "Information about GPU instances (g4dn.xlarge with 200GB storage on SUSE Linux)"
  value = {
    count            = length(aws_instance.gpu_instance)
    instance_type    = "g4dn.xlarge"
    operating_system = "SUSE Linux Enterprise Server 15 SP7"
    ami_id           = local.suse_ami_id
    gpu_type         = "NVIDIA T4"
    storage_size     = "200GB"
    instance_ids     = aws_instance.gpu_instance[*].id
    public_ips       = aws_instance.gpu_instance[*].public_ip
    private_ips      = aws_instance.gpu_instance[*].private_ip
    public_dns       = aws_instance.gpu_instance[*].public_dns
  }
}

output "security_groups" {
  description = "Security group information"
  value = {
    rancher_sg_id = aws_security_group.rancher_sg.id
    gpu_sg_id     = aws_security_group.gpu_sg.id
  }
}

output "key_pair_name" {
  description = "Name of the key pair used for SSH access"
  value       = aws_key_pair.vm_key.key_name
}

output "ssh_connection_commands" {
  description = "SSH commands to connect to the instances"
  value = {
    rancher_servers = [
      for i, instance in aws_instance.rancher_server :
      "ssh -i ~/.ssh/your-private-key ec2-user@${instance.public_ip}  # Amazon Linux"
    ]
    gpu_instances = [
      for i, instance in aws_instance.gpu_instance :
      "ssh -i ~/.ssh/your-private-key ec2-user@${instance.public_ip}  # SUSE Linux"
    ]
  }
}

output "web_urls" {
  description = "URLs to access the web servers and services on the instances"
  value = {
    rancher_servers = [
      for instance in aws_instance.rancher_server :
      "http://${instance.public_ip}"
    ]
    gpu_instances = [
      for instance in aws_instance.gpu_instance :
      "http://${instance.public_ip}"
    ]
  }
}

output "rancher_ui_urls" {
  description = "Potential Rancher UI URLs (after Rancher is installed)"
  value = [
    for instance in aws_instance.rancher_server :
    "https://${instance.public_ip}:8443"
  ]
}

output "deployment_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    total_instances = length(aws_instance.rancher_server) + length(aws_instance.gpu_instance)
    rancher_servers = {
      count = length(aws_instance.rancher_server)
      type  = "c6i.xlarge (4 vCPU, 8GB RAM, 150GB storage)"
      os    = "SUSE Linux Enterprise Server 15 SP7"
      ami   = local.suse_ami_id
      purpose = "Container orchestration with Rancher"
    }
    gpu_instances = {
      count = length(aws_instance.gpu_instance)
      type  = "g4dn.xlarge (4 vCPU, 16GB RAM, 1x NVIDIA T4, 200GB storage)"
      os    = "SUSE Linux Enterprise Server 15 SP7"
      ami   = local.suse_ami_id
      purpose = "GPU-accelerated ML/AI workloads"
    }
    networking = {
      vpc_cidr = aws_vpc.main.cidr_block
      public_subnet = aws_subnet.public.cidr_block
    }
  }
}

output "ansible_inventory" {
  description = "Ansible inventory in INI format"
  value = templatefile("${path.module}/ansible_inventory.tpl", {
    rancher_servers = aws_instance.rancher_server
    gpu_instances   = aws_instance.gpu_instance
  })
}

output "ansible_vars" {
  description = "Ansible variables for playbooks"
  value = {
    rancher_domain = "demo.rancher.com"
    rancher_server_ip = length(aws_instance.rancher_server) > 0 ? aws_instance.rancher_server[0].public_ip : ""
    project_name = var.project_name
    vpc_cidr = aws_vpc.main.cidr_block
    ssh_key_name = aws_key_pair.vm_key.key_name
  }
}