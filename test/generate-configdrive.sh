#!/bin/bash

# Simplified ConfigDrive format cloud-init configuration generation script
# Removes redundant SSH key information from meta_data.json

USERNAME="${1:-testuser}"
HOSTNAME="${2:-test-vm}"
INSTANCE_ID="${3:-iid-local01}"

# Determine tmp directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$SCRIPT_DIR/../tmp"

echo "🔧 Generating simplified ConfigDrive format cloud-init configuration..."
echo "Username: $USERNAME"
echo "Hostname: $HOSTNAME"
echo "Instance ID: $INSTANCE_ID"
echo "DataSource: ConfigDrive (OpenStack compatible)"
echo "Output directory: $TMP_DIR"

# Check and generate SSH keys
if [ ! -f ~/.ssh/id_rsa.pub ]; then
  echo "Generating SSH key pair..."
  ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_rsa -N ""
fi

SSH_PUBKEY=$(cat ~/.ssh/id_rsa.pub)

# Create tmp directory if not exists
mkdir -p "$TMP_DIR"

# Create ConfigDrive directory structure
echo "Creating ConfigDrive directory structure..."
rm -rf "$TMP_DIR/configdrive"
mkdir -p "$TMP_DIR/configdrive/openstack/latest"

# Generate minimized user_data (SSH keys configured only here)
cat >"$TMP_DIR/configdrive/openstack/latest/user_data" <<EOL
#cloud-config

# User configuration
users:
  - name: ${USERNAME}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin, sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ${SSH_PUBKEY}

# SSH configuration
ssh_pwauth: false
disable_root: false

# Timezone setting
timezone: Asia/Shanghai

# Final message
final_message: |
  Clean ConfigDrive Cloud-init setup completed!
  SSH should be available.
EOL

# Generate simplified meta_data.json (only basic metadata, no SSH keys)
cat >"$TMP_DIR/configdrive/openstack/latest/meta_data.json" <<EOL
{
  "uuid": "${INSTANCE_ID}",
  "hostname": "${HOSTNAME}",
  "name": "${HOSTNAME}",
  "launch_index": 0,
  "availability_zone": null,
  "meta": {}
}
EOL

# Auto install genisoimage if not installed
if ! command -v genisoimage &>/dev/null; then
  echo "💡 Installing genisoimage..."
  sudo apt-get update
  sudo apt-get install -y genisoimage
fi

# Generate ConfigDrive ISO image
echo "Generating ConfigDrive ISO image..."
if command -v genisoimage &>/dev/null; then
  genisoimage -output "$TMP_DIR/seed.iso" -volid config-2 -joliet -rock "$TMP_DIR/configdrive/"
elif command -v mkisofs &>/dev/null; then
  mkisofs -output "$TMP_DIR/seed.iso" -volid config-2 -joliet -rock "$TMP_DIR/configdrive/"
else
  echo "Error: genisoimage or mkisofs is required"
  echo "Ubuntu/Debian: sudo apt-get install genisoimage"
  echo "CentOS/RHEL: sudo yum install genisoimage"
  exit 1
fi

echo "✅ Simplified ConfigDrive format configuration files generated:"
echo "   - $TMP_DIR/configdrive/openstack/latest/user_data"
echo "   - $TMP_DIR/configdrive/openstack/latest/meta_data.json (simplified)"
echo "   - $TMP_DIR/seed.iso (volume label: config-2)"
echo "🔑 SSH public key: $(echo ${SSH_PUBKEY} | cut -d' ' -f1-2)..."
echo ""
echo "🔧 Simplified version features:"
echo "   - SSH keys only configured in user_data (avoid redundancy)"
echo "   - meta_data.json contains only basic metadata"
echo "   - Cleaner configuration structure"
echo "   - Reduced possibility of configuration conflicts"
echo ""
echo "📋 Directory structure:"
find "$TMP_DIR/configdrive" -type f | sort
echo ""
echo "Now you can run ./start-test-vm.sh to start the virtual machine"
