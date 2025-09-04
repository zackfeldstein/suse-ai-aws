# SUSE AI AWS Terraform Infrastructure

This Terraform configuration deploys a complete infrastructure on AWS with Rancher server and GPU-enabled instances for AI/ML workloads.

## 🏗️ Infrastructure Overview

### **Rancher Server (VM Type 1)**
- **Instance Type**: `c6i.xlarge` (4 vCPU, 8GB RAM)
- **Storage**: 150GB encrypted GP3 volume
- **Purpose**: Container orchestration platform
- **Ports**: SSH (22), HTTP (80), HTTPS (443), Rancher UI (8080, 8443)

### **GPU Instances (VM Type 2)**
- **Instance Type**: `g4dn.xlarge` (4 vCPU, 16GB RAM, 1x NVIDIA T4)
- **Operating System**: SUSE Linux Enterprise Server 15
- **Storage**: 200GB encrypted GP3 volume
- **Purpose**: GPU-accelerated ML/AI workloads
- **Ports**: SSH (22), HTTP (80), HTTPS (443), Jupyter/ML services (8888-8892)
- **NVIDIA Drivers**: Automatically installed using SUSE-specific method

### **Networking**
- **Custom VPC** with configurable CIDR (default: 10.0.0.0/16)
- **Public subnet** with internet gateway access
- **Separate security groups** for Rancher and GPU instances
- **Automatic public IP assignment**

## 🚀 Quick Start

### Phase 1: Infrastructure Deployment

1. **Prerequisites**
   - AWS CLI configured with appropriate credentials
   - Terraform installed (version >= 1.0)
   - Ansible installed (for configuration)
   - SSH key pair for instance access

2. **Clone and configure**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit `terraform.tfvars`** with your configuration:
   ```hcl
   # Required: Your SSH public key
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... your-public-key-here"
   
   # Optional: Adjust instance counts
   rancher_server_count = 1  # Number of Rancher servers
   gpu_instance_count = 1    # Number of GPU instances
   
   # Optional: Customize networking
   vpc_cidr = "10.0.0.0/16"
   public_subnet_cidr = "10.0.1.0/24"
   ```

4. **Deploy infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Phase 2: Software Configuration with Ansible

5. **Generate Ansible inventory**
   ```bash
   ./generate-inventory.sh
   ```

6. **Configure SUSE App Collection credentials**:
   ```bash
   cd ansible
   cp group_vars/secrets.yml.example group_vars/secrets.yml
   # Edit secrets.yml with your SUSE App Collection credentials
   ```

7. **Configure all systems**
   ```bash
   ansible-playbook -i inventory.ini site.yml
   ```

8. **Access Rancher Prime**
   - URL: https://demo.rancher.com
   - Username: admin
   - Password: admin (change immediately!)
   - Edition: Rancher Prime with enterprise features

## 🔐 AWS Configuration

Before using this Terraform configuration, you need to set up AWS credentials:

### **Method 1: AWS CLI (Recommended)**
```bash
# Install AWS CLI (if needed)
brew install awscli  # macOS
# or download from https://aws.amazon.com/cli/

# Configure credentials
aws configure
# Enter your Access Key ID, Secret Access Key, region (us-west-2), and format (json)

# Verify configuration
aws sts get-caller-identity
```

### **Method 2: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Make persistent (add to ~/.zshrc or ~/.bashrc)
echo 'export AWS_ACCESS_KEY_ID="your-access-key"' >> ~/.zshrc
echo 'export AWS_SECRET_ACCESS_KEY="your-secret-key"' >> ~/.zshrc
echo 'export AWS_DEFAULT_REGION="us-west-2"' >> ~/.zshrc
```

### **Getting AWS Credentials**
1. **AWS Console** → **IAM** → **Users** → **Create User**
2. **Attach policies**: `AmazonEC2FullAccess`, `AmazonVPCFullAccess`, `IAMReadOnlyAccess`
3. **Security credentials** → **Create access key** → **Download**

### **Test Your Configuration**
```bash
# Verify AWS access
aws sts get-caller-identity

# Test Terraform
terraform init
terraform plan
```

## ⚙️ Configuration Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `aws_region` | AWS region for deployment | `us-west-2` | string |
| `project_name` | Project name for resource naming | `suse-ai-aws` | string |
| `public_key` | SSH public key for instance access | - | **Required** |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` | string |
| `public_subnet_cidr` | Public subnet CIDR block | `10.0.1.0/24` | string |
| `rancher_server_count` | Number of Rancher servers (0-5) | `1` | number |
| `gpu_instance_count` | Number of GPU instances (0-10) | `1` | number |
| `enable_detailed_monitoring` | Enable CloudWatch detailed monitoring | `false` | bool |
| `additional_tags` | Additional tags for resources | `{}` | map(string) |

## 📊 Instance Specifications

### Rancher Server (c6i.xlarge)
- **vCPUs**: 4
- **Memory**: 8 GiB
- **Storage**: 150GB GP3 (encrypted)
- **Network**: Up to 12.5 Gbps
- **Use Case**: Container orchestration, Kubernetes management
- **Pre-installed**: Docker, Docker Compose

### GPU Instance (g4dn.xlarge)
- **vCPUs**: 4
- **Memory**: 16 GiB
- **GPU**: 1x NVIDIA T4 (16GB GPU memory)
- **Storage**: 200GB GP3 (encrypted)
- **Network**: Up to 25 Gbps
- **Operating System**: SUSE Linux Enterprise Server 15
- **Use Case**: Machine learning, AI training, GPU computing
- **Pre-installed**: NVIDIA drivers (SUSE-optimized), Docker with GPU support, nvidia-container-toolkit

## 🔌 Outputs

After deployment, you'll receive:

- **VPC and networking details**
- **Instance information** (IDs, IPs, DNS names)
- **SSH connection commands**
- **Web URLs** for basic instance info
- **Rancher UI URLs** (after Rancher installation)
- **Deployment summary** with full specifications

## 🐳 Post-Deployment: Installing Rancher

After your Rancher server is running, install Rancher:

```bash
# SSH into your Rancher server
ssh -i ~/.ssh/your-private-key ec2-user@<rancher-server-ip>

# Install Rancher (latest stable)
sudo docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:latest
```

Access Rancher UI at: `https://<rancher-server-ip>`

## 🎮 GPU Driver Installation

The GPU instances automatically install NVIDIA drivers using the SUSE Linux Enterprise Server optimized method:

```bash
# Add NVIDIA CUDA repository for SLES15
zypper ar https://developer.download.nvidia.com/compute/cuda/repos/sles15/x86_64/ cuda-sle15
zypper --gpg-auto-import-keys refresh

# Install preferred signed driver
zypper install -y --auto-agree-with-licenses nv-prefer-signed-open-driver

# Get driver version and install compute utilities
version=$(rpm -qa --queryformat '%{VERSION}\n' nv-prefer-signed-open-driver | cut -d "_" -f1 | sort -u | tail -n 1)
zypper install -y --auto-agree-with-licenses nvidia-compute-utils-G06=${version}
```

After deployment, you can verify GPU functionality:
```bash
# SSH into GPU instance
ssh -i ~/.ssh/your-private-key ec2-user@<gpu-instance-ip>

# Check GPU status
nvidia-smi

# Test Docker GPU support
sudo docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
```

## 🎯 Usage Scenarios

### Development Environment
```hcl
rancher_server_count = 1
gpu_instance_count = 1
```

### Production Setup
```hcl
rancher_server_count = 3  # HA setup
gpu_instance_count = 5    # Multiple GPU workers
enable_detailed_monitoring = true
```

### ML Training Cluster
```hcl
rancher_server_count = 1
gpu_instance_count = 10   # Maximum GPU instances
```

## 🔒 Security Features

- **Encrypted storage** for all EBS volumes
- **Separate security groups** for different instance types
- **SSH key-based authentication**
- **HTTPS-ready** configurations
- **VPC isolation** with custom networking

### Security Group Rules

**Rancher Server**:
- SSH (22), HTTP (80), HTTPS (443)
- Rancher UI (8080, 8443)

**GPU Instances**:
- SSH (22), HTTP (80), HTTPS (443)
- Jupyter/ML services (8888-8892)

## 💰 Cost Estimation (us-west-2)

- **c6i.xlarge**: ~$0.192/hour
- **g4dn.xlarge**: ~$0.526/hour

**Example monthly costs**:
- 1 Rancher + 1 GPU: ~$516/month
- 1 Rancher + 5 GPU: ~$1,958/month

*Prices subject to change. Monitor AWS billing dashboard.*

## 🛠️ Troubleshooting

### Common Issues

1. **GPU drivers not loading**
   - Check instance state: `nvidia-smi`
   - Reboot instance if needed
   - Verify g4dn.xlarge availability in region

2. **Rancher UI not accessible**
   - Check security group rules
   - Verify Docker container status
   - Allow time for initial setup (5-10 minutes)

3. **SSH connection fails**
   - Verify public key format
   - Check security group SSH rules
   - Ensure instance is in "running" state

### Useful Commands

```bash
# Check GPU status
nvidia-smi

# Check Docker status
sudo systemctl status docker

# View Rancher container logs
sudo docker logs <container-id>

# Check instance metadata
curl http://169.254.169.254/latest/meta-data/
```

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all instances and data.

## 📋 What's Included

- ✅ Custom VPC with public subnet
- ✅ Internet gateway and routing
- ✅ Security groups with appropriate rules
- ✅ SSH key pair management
- ✅ Encrypted EBS volumes
- ✅ Instance initialization scripts
- ✅ Comprehensive outputs
- ✅ Cost-optimized GP3 storage
- ✅ GPU driver installation
- ✅ Docker with GPU support

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is licensed under the MIT License.