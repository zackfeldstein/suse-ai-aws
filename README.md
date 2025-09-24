# SUSE AI AWS Infrastructure with RKE2 and Rancher

This project deploys a complete Kubernetes infrastructure on AWS using Terraform and Ansible, featuring RKE2 clusters, Rancher management platform, and NVIDIA GPU support for AI/ML workloads.

## 🏗️ Infrastructure Overview

### **Rancher Management Server**
- **Instance Type**: `c6i.xlarge` (4 vCPU, 8GB RAM)
- **Storage**: 150GB encrypted GP3 volume
- **Operating System**: SUSE Linux Enterprise Server 15 SP7
- **Purpose**: Runs RKE2 single-node cluster + Rancher Prime for Kubernetes management
- **Access**: `https://demo.rancher.com`

### **GPU Workload Cluster**
- **Instance Type**: `g4dn.xlarge` (4 vCPU, 16GB RAM, 1x NVIDIA T4)
- **Operating System**: SUSE Linux Enterprise Server 15 SP7
- **Storage**: 200GB encrypted GP3 volume
- **Purpose**: Standalone RKE2 cluster optimized for GPU workloads
- **Features**: NVIDIA drivers, GPU device plugin, local-path storage

### **Networking**
- **Custom VPC** with configurable CIDR (default: 10.0.0.0/16)
- **Public subnet** with internet gateway access
- **Security groups** configured for RKE2 and Rancher access
- **DNS resolution** via `/etc/hosts` for demo.rancher.com

## 🚀 Quick Start

### Phase 1: Infrastructure Deployment with Terraform

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

6. **Configure credentials** (optional, for Rancher Prime):
   ```bash
   cd ansible
   cp group_vars/secrets.yml.example group_vars/secrets.yml
   # Edit secrets.yml with your SUSE App Collection credentials
   ```

7. **Deploy RKE2 clusters, Rancher, and NVIDIA drivers**
   ```bash
   cd ansible
   ansible-playbook -i inventory.ini site.yml
   ```

### Phase 3: Access Your Clusters

8. **Access Rancher Management UI**
   - URL: `https://demo.rancher.com`
   - Username: `admin`
   - Password: `admin` (change immediately!)

9. **Access GPU Cluster** (optional - for direct kubectl access)
   ```bash
   ssh ec2-user@<gpu-instance-ip>
   kubectl --kubeconfig=/etc/rancher/rke2/rke2.yaml get nodes
   ```

## 🎯 What Gets Deployed

### Rancher Management Cluster
- **RKE2 single-node cluster** (control-plane + etcd + master)
- **Rancher Prime** container management platform
- **cert-manager** with self-signed certificates
- **local-path storage** as default storage class
- **Single replica** deployment optimized for demo/dev

### GPU Workload Cluster  
- **Standalone RKE2 cluster** (separate from Rancher)
- **NVIDIA Tesla T4** GPU with drivers installed
- **NVIDIA GPU device plugin** for Kubernetes
- **local-path storage** provisioner
- **Docker with GPU support** (nvidia-container-toolkit)
- **Ready for GPU workloads** (PyTorch, TensorFlow, etc.)

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
```

### **Getting AWS Credentials**
1. **AWS Console** → **IAM** → **Users** → **Create User**
2. **Attach policies**: `AmazonEC2FullAccess`, `AmazonVPCFullAccess`, `IAMReadOnlyAccess`
3. **Security credentials** → **Create access key** → **Download**

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

## 📊 Cluster Specifications

### Rancher Management Cluster
- **Kubernetes**: v1.28.5+rke2r1
- **Rancher**: v2.11.3 (Prime edition ready)
- **Storage**: local-path provisioner
- **Networking**: Flannel CNI
- **Access**: HTTPS with self-signed certs

### GPU Workload Cluster
- **Kubernetes**: v1.32.7+rke2r1
- **GPU**: NVIDIA T4 (16GB VRAM)
- **Drivers**: NVIDIA 580.65.06 with CUDA 13.0
- **Storage**: local-path provisioner (default)
- **GPU Plugin**: NVIDIA k8s-device-plugin v0.14.5

## 🎮 GPU Testing

After deployment, test GPU functionality:

```bash
# SSH into GPU instance
ssh ec2-user@<gpu-instance-ip>

# Check GPU status
nvidia-smi

# Test Kubernetes GPU resources
kubectl --kubeconfig=/etc/rancher/rke2/rke2.yaml describe nodes | grep nvidia.com/gpu

# Run GPU test script
./test-gpu.sh
```

## 🔗 Importing GPU Cluster into Rancher

To manage your GPU cluster through Rancher:

1. Access Rancher UI at `https://demo.rancher.com`
2. Go to **Cluster Management** → **Import Existing**
3. Follow the import wizard using the GPU cluster details
4. Use the node token displayed during deployment

## 🛠️ Troubleshooting

### Common Issues

1. **RKE2 not starting**
   ```bash
   sudo systemctl status rke2-server
   sudo journalctl -u rke2-server -f
   ```

2. **Rancher pod stuck creating**
   - Check if `tls-ca` secret exists
   - Verify cert-manager is running
   - Check storage class availability

3. **GPU not detected**
   ```bash
   nvidia-smi
   sudo systemctl status rke2-server
   kubectl get nodes -o yaml | grep nvidia
   ```

4. **DNS resolution issues**
   - Verify `/etc/hosts` contains demo.rancher.com entry
   - Check security group allows HTTPS (443)

### Useful Commands

```bash
# Check RKE2 cluster status
kubectl --kubeconfig=/etc/rancher/rke2/rke2.yaml get nodes -o wide

# Check Rancher pods
kubectl --kubeconfig=/etc/rancher/rke2/rke2.yaml get pods -n cattle-system

# Check GPU device plugin
kubectl --kubeconfig=/etc/rancher/rke2/rke2.yaml get pods -n kube-system | grep nvidia

# View RKE2 logs
sudo journalctl -u rke2-server -f
```

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all instances, clusters, and data.

## 📋 What's Included

- ✅ **Terraform**: AWS infrastructure (VPC, EC2, Security Groups)
- ✅ **Ansible**: Automated software deployment and configuration
- ✅ **RKE2**: Production-ready Kubernetes clusters
- ✅ **Rancher**: Kubernetes management platform
- ✅ **NVIDIA Support**: GPU drivers and Kubernetes device plugin
- ✅ **Storage**: local-path provisioner for persistent volumes
- ✅ **Security**: Encrypted storage, security groups, SSH keys
- ✅ **DNS**: Custom domain resolution for Rancher access

## 🎯 Use Cases

- **AI/ML Development**: GPU-accelerated training and inference
- **Kubernetes Learning**: Multi-cluster management with Rancher
- **Edge Computing**: Lightweight RKE2 clusters
- **Container Orchestration**: Production-ready Kubernetes setup
- **Hybrid Cloud**: Import existing clusters into Rancher

## 💰 Cost Estimation (us-west-2)

- **c6i.xlarge**: ~$0.192/hour (~$138/month)
- **g4dn.xlarge**: ~$0.526/hour (~$378/month)

**Total for default setup**: ~$516/month

*Prices subject to change. Monitor AWS billing dashboard.*

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is licensed under the MIT License.