#!/bin/bash

# Cleanup script for test temporary files
# Usage: ./cleanup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$SCRIPT_DIR/../tmp"

echo "🧹 Cleaning up test temporary files..."

# Stop any running QEMU processes
VM_PIDS=$(pgrep -f "qemu-system-x86_64.*\.qcow2")
if [ -n "$VM_PIDS" ]; then
    echo "🛑 Stopping running VM processes: $VM_PIDS"
    echo "$VM_PIDS" | xargs kill -TERM 2>/dev/null
    sleep 3
    echo "$VM_PIDS" | xargs kill -KILL 2>/dev/null
fi

# Clean temporary files
if [ -d "$TMP_DIR" ]; then
    echo "📂 Cleaning temporary files in $TMP_DIR"

    # Remove cloud-init files
    rm -rf "$TMP_DIR/configdrive"
    rm -f "$TMP_DIR/seed.iso"

    # Remove VM runtime files
    rm -f "$TMP_DIR"/monitor-*.sock
    rm -f "$TMP_DIR"/vm-*.pid
    rm -f "$TMP_DIR/vm_output.log"

    echo "✅ Cleanup completed"

    # Show remaining files
    if ls "$TMP_DIR"/* >/dev/null 2>&1; then
        echo "📋 Remaining files in tmp directory:"
        ls -la "$TMP_DIR"
    else
        echo "📋 tmp directory is now clean (except for image files)"
    fi
else
    echo "ℹ️  tmp directory does not exist"
fi

echo ""
echo "🎯 To start fresh testing, run:"
echo "   ./generate-configdrive.sh"
echo "   ./start-test-vm.sh [image_file]"
