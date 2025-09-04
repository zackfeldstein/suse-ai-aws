# Ansible Configuration for SUSE AI AWS Infrastructure

This directory contains Ansible playbooks to configure your AWS infrastructure deployed by Terraform.

## What Gets Installed

### Rancher Server (c6i.xlarge)
- ✅ **RKE2** single-node Kubernetes cluster
- ✅ **Rancher Prime** container management platform
- ✅ **cert-manager** with SUSE OCI charts for SSL certificate management
- ✅ **Self-signed certificates** for `demo.rancher.com`
- ✅ **Hosts file** updated to point `demo.rancher.com` to Rancher server IP
- ✅ **App Collection integration** for SUSE enterprise features

### GPU Node (g4dn.xlarge)
- ✅ **NVIDIA drivers** (using your specified installation method)
- ✅ **Docker** with GPU support
- ✅ **nvidia-container-toolkit** for GPU containers
- ✅ **Hosts file** updated to point `demo.rancher.com` to Rancher server IP

## Prerequisites

1. **Ansible installed** on your local machine:
   ```bash
   # macOS
   brew install ansible
   
   # Ubuntu/Debian
   sudo apt install ansible
   
   # RHEL/CentOS
   sudo yum install ansible
   ```

2. **SSH access** to your instances (make sure your SSH key is loaded)

**Note**: This setup uses only built-in Ansible modules - no external collections required!

## Quick Start

1. **Generate inventory from Terraform**:
   ```bash
   # From the project root
   ./generate-inventory.sh
   ```

2. **Configure SUSE App Collection credentials for Rancher Prime**:
   ```bash
   cd ansible
   cp group_vars/secrets.yml.example group_vars/secrets.yml
   # Edit secrets.yml with your SUSE App Collection credentials
   ```

3. **Test connectivity**:
   ```bash
   ansible -i inventory.ini all -m ping
   ```

4. **Run the complete setup**:
   ```bash
   ansible-playbook -i inventory.ini site.yml
   ```

## Individual Playbooks

You can also run specific parts:

```bash
# Only setup RKE2 and Rancher
ansible-playbook -i inventory.ini site.yml --tags rancher

# Only setup GPU drivers
ansible-playbook -i inventory.ini site.yml --tags gpu

# Only update hosts files
ansible-playbook -i inventory.ini site.yml --tags hosts
```

## SUSE App Collection Credentials

To install Rancher Prime, you need SUSE App Collection credentials:

1. **Get credentials** from [SUSE Customer Center](https://www.suse.com/support/)
2. **Copy the example file**:
   ```bash
   cp group_vars/secrets.yml.example group_vars/secrets.yml
   ```
3. **Edit secrets.yml** with your actual credentials:
   ```yaml
   app_collection_username: "your-email@company.com"
   app_collection_password: "your-secure-password"
   ```

**Note**: The `secrets.yml` file is automatically ignored by git to protect your credentials.

## Accessing Rancher

After the playbook completes:

1. **Access Rancher Prime UI**: https://demo.rancher.com
   - **Username**: admin
   - **Password**: admin (change this immediately!)
   - **Edition**: Rancher Prime with enterprise features

2. **SSH to Rancher server** to use kubectl:
   ```bash
   ssh ec2-user@<rancher-server-ip>
   kubectl get nodes
   kubectl get pods -A
   ```

## Configuration Variables

Edit `group_vars/all.yml` to customize:

```yaml
rancher_domain: demo.rancher.com
rancher_version: "2.8.0"
rke2_version: "v1.28.5+rke2r1"
use_letsencrypt: false  # Set to true for production
```

## Troubleshooting

### Common Issues

1. **Ansible connection failures**:
   ```bash
   # Test SSH connectivity
   ssh -i ~/.ssh/your-key ec2-user@<instance-ip>
   
   # Check inventory
   cat inventory.ini
   ```

2. **RKE2 installation fails**:
   ```bash
   # SSH to Rancher server and check logs
   sudo journalctl -u rke2-server -f
   ```

3. **NVIDIA drivers not working**:
   ```bash
   # SSH to GPU node and test
   nvidia-smi
   sudo docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
   ```

4. **Rancher UI not accessible**:
   - Check if `demo.rancher.com` resolves to the correct IP
   - Verify the hosts file was updated: `cat /etc/hosts`
   - Check Rancher pods: `kubectl get pods -n cattle-system`

### Manual Verification

```bash
# On Rancher server
kubectl get nodes
kubectl get pods -A
curl -k https://demo.rancher.com

# On GPU node  
nvidia-smi
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
```

## File Structure

```
ansible/
├── ansible.cfg           # Ansible configuration
├── site.yml             # Main playbook
├── inventory.ini        # Generated from Terraform
├── requirements.yml     # Ansible collections
├── group_vars/
│   ├── all.yml         # Global variables
│   └── terraform_vars.yml  # Variables from Terraform
└── playbooks/
    ├── rke2-server.yml     # RKE2 installation
    ├── rancher-install.yml # Rancher installation
    └── nvidia-drivers.yml  # NVIDIA driver setup
```

## Production Considerations

For production use:

1. **Change default passwords**
2. **Use Let's Encrypt certificates**:
   ```yaml
   use_letsencrypt: true
   letsencrypt_email: "your-email@domain.com"
   ```
3. **Use proper DNS** instead of hosts file entries
4. **Configure backup strategies** for RKE2 and Rancher
5. **Set up monitoring** and logging
