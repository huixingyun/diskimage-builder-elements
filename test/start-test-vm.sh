#!/bin/bash

# Flexible virtual machine startup script
# Usage: ./start-test-vm.sh [image_file] [memory_mb] [cpu_cores] [ssh_port]

# Default parameters
DEFAULT_IMAGE_FILE="../tmp/image-gpu-mini_20250606.qcow2"
DEFAULT_MEMORY="4096"
DEFAULT_CPUS="4"
DEFAULT_SSH_PORT="2222"

# Determine tmp directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$SCRIPT_DIR/../tmp"

# Parse command line arguments
IMAGE_FILE="${1:-$DEFAULT_IMAGE_FILE}"
MEMORY="${2:-$DEFAULT_MEMORY}"
CPUS="${3:-$DEFAULT_CPUS}"
SSH_PORT="${4:-$DEFAULT_SSH_PORT}"

# Show help information
show_help() {
    echo "🚀 Flexible Virtual Machine Startup Script"
    echo ""
    echo "Usage: $0 [image_file] [memory_mb] [cpu_cores] [ssh_port]"
    echo ""
    echo "Parameters:"
    echo "  image_file  - Image file path (default: $DEFAULT_IMAGE_FILE)"
    echo "  memory_mb   - Memory size in MB (default: $DEFAULT_MEMORY)"
    echo "  cpu_cores   - CPU core count (default: $DEFAULT_CPUS)"
    echo "  ssh_port    - SSH port number (default: $DEFAULT_SSH_PORT)"
    echo ""
    echo "Examples:"
    echo "  $0                                           # Use default parameters"
    echo "  $0 ../output/image-gpu-mini_20241225.qcow2  # Specify image file"
    echo "  $0 image.qcow2 8192 8 2223                  # Specify all parameters"
    echo ""
    echo "Exit methods:"
    echo "  - Ctrl+A then C, type 'quit'"
    echo "  - Ctrl+A then X (direct exit)"
    echo "  - Inside VM: 'sudo shutdown -h now'"
}

# Check for help request
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

echo "🚀 Starting test virtual machine..."
echo "   Image file: $IMAGE_FILE"
echo "   Memory: ${MEMORY}MB"
echo "   CPU cores: $CPUS"
echo "   SSH port: $SSH_PORT"
echo "   Temp directory: $TMP_DIR"
echo ""

# Create tmp directory if not exists
mkdir -p "$TMP_DIR"

# Check dependency files
if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ Error: Image file $IMAGE_FILE does not exist"
    echo ""
    echo "💡 Tip: Check image file path, or use the following command to find image files:"
    echo "   find .. -name '*.qcow2' -type f 2>/dev/null | head -5"
    exit 1
fi

if [ ! -f "$TMP_DIR/seed.iso" ]; then
    echo "❌ Error: cloud-init ISO file $TMP_DIR/seed.iso does not exist"
    echo "Please run ./generate-configdrive.sh first to generate configuration files"
    exit 1
fi

# Check if port is occupied
if ss -ltn | grep -q ":$SSH_PORT "; then
    echo "⚠️  Warning: Port $SSH_PORT is already in use"
    echo "Please use a different port number or close the program using this port"
    exit 1
fi

echo "📋 Startup parameter details:"
echo "   - Enable KVM hardware acceleration"
echo "   - Use VirtIO disk and network drivers"
echo "   - SSH port forwarding: localhost:$SSH_PORT -> VM:22"
echo "   - Serial output redirected to standard output"
echo ""

echo "💡 Troubleshooting options:"
echo "   1. If startup fails, try disabling KVM: remove -enable-kvm from startup command"
echo "   2. If network issues occur, check firewall settings"
echo "   3. If SSH connection fails, wait longer for system to fully start"
echo ""

echo "📝 QEMU exit methods:"
echo "   - Ctrl+A then C, type 'quit'"
echo "   - Ctrl+A then X (direct exit)"
echo ""

echo "⏳ Starting virtual machine..."
echo "🔍 Watch for cloud-init related log output..."
echo ""

# Create runtime files in tmp directory
MONITOR_SOCK="$TMP_DIR/monitor-$$-$(date +%s).sock"
PID_FILE="$TMP_DIR/vm-$$-$(date +%s).pid"

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning temporary files..."
    rm -f "$MONITOR_SOCK" "$PID_FILE"
}
trap cleanup EXIT

# Start virtual machine
qemu-system-x86_64 \
    -m $MEMORY \
    -smp $CPUS \
    -enable-kvm \
    -cpu host \
    -machine type=pc,accel=kvm \
    -drive file="$IMAGE_FILE",format=qcow2,if=virtio,cache=writeback \
    -drive file="$TMP_DIR/seed.iso",format=raw,if=virtio,readonly=on \
    -netdev user,id=net0,hostfwd=tcp::$SSH_PORT-:22 \
    -device virtio-net-pci,netdev=net0 \
    -device virtio-rng-pci \
    -display none \
    -serial stdio \
    -monitor unix:"$MONITOR_SOCK",server,nowait \
    -pidfile "$PID_FILE"
