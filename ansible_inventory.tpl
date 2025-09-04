[rancher_servers]
%{ for idx, server in rancher_servers ~}
${server.tags.Name} ansible_host=${server.public_ip} ansible_user=ec2-user private_ip=${server.private_ip} instance_id=${server.id}
%{ endfor ~}

[gpu_nodes]
%{ for idx, gpu in gpu_instances ~}
${gpu.tags.Name} ansible_host=${gpu.public_ip} ansible_user=ec2-user private_ip=${gpu.private_ip} instance_id=${gpu.id}
%{ endfor ~}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3

