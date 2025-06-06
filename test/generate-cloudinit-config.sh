#!/bin/bash

# cloud-init configuration generation script
# Usage: ./generate-cloudinit-config.sh [username] [hostname] [instance-id]

# Default configuration
USERNAME="${1:-testuser}"
HOSTNAME="${2:-test-vm}"
INSTANCE_ID="${3:-iid-local01}"

echo "Generating cloud-init configuration files..."
echo "Username: $USERNAME"
echo "Hostname: $HOSTNAME"
echo "Instance ID: $INSTANCE_ID"

# Check and generate SSH key
if [ ! -f ~/.ssh/id_rsa.pub ]; then
  echo "Generating SSH key pair..."
  ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_rsa -N ""
fi

SSH_PUBKEY=$(cat ~/.ssh/id_rsa.pub)

# Generate user-data
cat >user-data <<EOL
#cloud-config
users:
  - name: ${USERNAME}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    shell: /bin/bash
    ssh_authorized_keys:
      - ${SSH_PUBKEY}

ssh_pwauth: false
disable_root: false
ssh_authorized_keys:
  - ${SSH_PUBKEY}

timezone: Asia/Shanghai

packages:
  - htop
  - vim
  - curl
  - wget
  - net-tools

runcmd:
  - echo "Cloud-init setup completed at \$(date)" >> /var/log/setup.log
  - systemctl enable ssh
  - systemctl start ssh
EOL

# Generate meta-data
cat >meta-data <<EOL
instance-id: ${INSTANCE_ID}
local-hostname: ${HOSTNAME}
EOL

# Create configuration directory and make ISO image
mkdir -p cloudinit
cp user-data meta-data cloudinit/

# Generate cloud-init ISO image
if command -v genisoimage &>/dev/null; then
  genisoimage -output seed.iso -volid cidata -joliet -rock cloudinit/
elif command -v mkisofs &>/dev/null; then
  mkisofs -output seed.iso -volid cidata -joliet -rock cloudinit/
else
  echo "Error: genisoimage or mkisofs is required"
  echo "Ubuntu/Debian: sudo apt-get install genisoimage"
  echo "CentOS/RHEL: sudo yum install genisoimage"
  exit 1
fi

echo "✅ Configuration files have been generated:"
echo "   - user-data"
echo "   - meta-data"
echo "   - seed.iso"
echo "🔑 SSH public key: $(echo ${SSH_PUBKEY} | cut -d' ' -f1-2)..."
echo ""
echo "Now you can run ./start-test-vm.sh to start the virtual machine"
