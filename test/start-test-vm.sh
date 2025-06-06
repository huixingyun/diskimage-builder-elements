#!/bin/bash

# QEMU virtual machine startup script
# Usage: ./start-test-vm.sh [image-file] [memory-MB] [cpu-count] [ssh-port]

IMAGE_FILE="${1:-image-gpu-mini.qcow2}"
MEMORY="${2:-2048}"
CPUS="${3:-2}"
SSH_PORT="${4:-2222}"

echo "Checking dependency files..."

if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ Error: Image file $IMAGE_FILE does not exist"
    echo "Please ensure the image file is generated or specify the correct path"
    exit 1
fi

if [ ! -f "seed.iso" ]; then
    echo "❌ Error: cloud-init ISO file seed.iso does not exist"
    echo "Please run ./generate-cloudinit-config.sh first to generate configuration files"
    exit 1
fi

echo "✅ Dependency files check completed"
echo ""
echo "🚀 Starting test virtual machine..."
echo "   Image file: $IMAGE_FILE"
echo "   Memory: ${MEMORY}MB"
echo "   CPU count: $CPUS"
echo "   SSH port: $SSH_PORT"
echo ""
echo "📝 QEMU exit methods:"
echo "   Method 1: Ctrl+A then press C, type 'quit'"
echo "   Method 2: Ctrl+A then press X (direct exit)"
echo "   Method 3: SSH login and execute 'sudo poweroff'"
echo ""
echo "🔗 After startup, you can SSH login with:"
echo "   ssh -p $SSH_PORT testuser@localhost"
echo ""
echo "Starting virtual machine..."

qemu-system-x86_64 \
    -m $MEMORY \
    -smp $CPUS \
    -drive file=$IMAGE_FILE,format=qcow2 \
    -drive file=seed.iso,format=raw \
    -net nic -net user,hostfwd=tcp::$SSH_PORT-:22 \
    -nographic
