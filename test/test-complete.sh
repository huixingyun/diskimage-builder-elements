#!/bin/bash

# Complete image testing script
# Automates: cloud-init configuration generation, VM startup, SSH connection testing
# Usage: ./test-complete.sh [image_file] [username] [hostname]

# Default parameters
DEFAULT_IMAGE_FILE="../output/image-gpu-mini_$(date +%Y%m%d).qcow2"
DEFAULT_USERNAME="testuser"
DEFAULT_HOSTNAME="test-vm"
DEFAULT_MEMORY="4096"
DEFAULT_CPUS="4"
DEFAULT_SSH_PORT="2222"

# Parse command line arguments
IMAGE_FILE="${1:-$DEFAULT_IMAGE_FILE}"
USERNAME="${2:-$DEFAULT_USERNAME}"
HOSTNAME="${3:-$DEFAULT_HOSTNAME}"
MEMORY="${4:-$DEFAULT_MEMORY}"
CPUS="${5:-$DEFAULT_CPUS}"
SSH_PORT="${6:-$DEFAULT_SSH_PORT}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$SCRIPT_DIR/../tmp"

# Show help information
show_help() {
    echo "🧪 Complete Image Testing Script"
    echo ""
    echo "Usage: $0 [image_file] [username] [hostname] [memory_mb] [cpu_cores] [ssh_port]"
    echo ""
    echo "Parameters:"
    echo "  image_file  - Image file path"
    echo "  username    - Test username (default: $DEFAULT_USERNAME)"
    echo "  hostname    - Hostname (default: $DEFAULT_HOSTNAME)"
    echo "  memory_mb   - Memory size in MB (default: $DEFAULT_MEMORY)"
    echo "  cpu_cores   - CPU core count (default: $DEFAULT_CPUS)"
    echo "  ssh_port    - SSH port number (default: $DEFAULT_SSH_PORT)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Auto-find today's image file"
    echo "  $0 ../output/image-gpu-mini.qcow2    # Specify image file"
    echo "  $0 image.qcow2 ubuntu my-vm          # Specify image, username and hostname"
    echo ""
    echo "Features:"
    echo "  1. Auto-find and verify image files"
    echo "  2. Generate cloud-init configuration"
    echo "  3. Start test VM"
    echo "  4. Test SSH connection and system functionality"
    echo "  5. Optional: Test CUDA and PyTorch environment"
    echo ""
}

# Check for help request
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Color output functions
print_step() {
    echo ""
    echo "🔷 ======== $1 ========"
    echo ""
}

print_info() {
    echo "ℹ️  $1"
}

print_success() {
    echo "✅ $1"
}

print_error() {
    echo "❌ $1"
}

print_warning() {
    echo "⚠️  $1"
}

# Find image file
find_image_file() {
    print_step "Finding Image File"

    if [ -f "$IMAGE_FILE" ]; then
        print_success "Found specified image file: $IMAGE_FILE"
        return 0
    fi

    print_info "Specified image file does not exist, trying auto-discovery..."

    # Try to find latest image files
    local found_files=()

    # Search in current directory and common directories
    for dir in "../output" "../tmp" "."; do
        if [ -d "$dir" ]; then
            while IFS= read -r -d '' file; do
                found_files+=("$file")
            done < <(find "$dir" -name "*.qcow2" -type f -print0 2>/dev/null | head -z -n 10)
        fi
    done

    if [ ${#found_files[@]} -eq 0 ]; then
        print_error "No .qcow2 image files found"
        print_info "Please ensure image files exist or specify correct path"
        return 1
    fi

    # Select the latest image file
    local latest_file=$(printf '%s\n' "${found_files[@]}" | sort -V | tail -1)
    IMAGE_FILE="$latest_file"

    print_success "Auto-selected image file: $IMAGE_FILE"
    return 0
}

# Generate cloud-init configuration
generate_cloud_init() {
    print_step "Generating Cloud-init Configuration"

    if ! "$SCRIPT_DIR/generate-configdrive.sh" "$USERNAME" "$HOSTNAME" "iid-test-$(date +%s)"; then
        print_error "Failed to generate cloud-init configuration"
        return 1
    fi

    print_success "Cloud-init configuration generated successfully"
    return 0
}

# Start virtual machine
start_vm() {
    print_step "Starting Test Virtual Machine"

    print_info "VM Configuration:"
    print_info "  - Image: $IMAGE_FILE"
    print_info "  - Memory: ${MEMORY}MB"
    print_info "  - CPU: ${CPUS} cores"
    print_info "  - SSH Port: $SSH_PORT"
    print_info "  - Username: $USERNAME"
    print_info "  - Temp directory: $TMP_DIR"

    # Create tmp directory if not exists
    mkdir -p "$TMP_DIR"

    # Check if port is occupied
    if ss -ltn | grep -q ":$SSH_PORT "; then
        print_error "Port $SSH_PORT is already in use"
        print_info "Please close the program using this port or use a different port"
        return 1
    fi

    print_info "Starting VM in background..."

    # Start VM (background execution)
    "$SCRIPT_DIR/start-test-vm.sh" "$IMAGE_FILE" "$MEMORY" "$CPUS" "$SSH_PORT" >"$TMP_DIR/vm_output.log" 2>&1 &
    local vm_pid=$!

    print_info "VM process PID: $vm_pid"
    print_info "Startup log saved to: $TMP_DIR/vm_output.log"

    # Wait for VM startup
    print_info "Waiting for VM startup (max 90 seconds)..."

    for i in {1..18}; do
        if nc -z localhost $SSH_PORT 2>/dev/null; then
            print_success "VM SSH port is open"
            return 0
        fi

        if ! kill -0 $vm_pid 2>/dev/null; then
            print_error "VM process exited unexpectedly"
            print_info "Check startup log: tail $TMP_DIR/vm_output.log"
            return 1
        fi

        printf "."
        sleep 5
    done

    echo ""
    print_warning "VM startup timeout, but will continue SSH connection testing"
    return 0
}

# Test SSH connection
test_ssh() {
    print_step "Testing SSH Connection and System Information"

    if ! "$SCRIPT_DIR/test-ssh.sh" "$SSH_PORT" "$USERNAME" "localhost" 8 20; then
        print_error "SSH connection test failed"
        return 1
    fi

    print_success "SSH connection test passed"
    return 0
}

# Optional deep learning environment test
test_deep_learning() {
    print_step "Deep Learning Environment Test (Optional)"

    echo "Do you want to test CUDA and PyTorch environment? (y/N)"
    read -t 10 -n 1 answer
    echo ""

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        print_info "Starting CUDA test..."
        if ssh -o BatchMode=yes -o ConnectTimeout=15 -p $SSH_PORT $USERNAME@localhost "sudo bash /root/verify_cuda.sh 2>/dev/null"; then
            print_success "CUDA test passed"
        else
            print_warning "CUDA test failed or not applicable"
        fi

        print_info "Starting PyTorch test..."
        if ssh -o BatchMode=yes -o ConnectTimeout=15 -p $SSH_PORT $USERNAME@localhost "python3 /root/verify_pytorch.py 2>/dev/null"; then
            print_success "PyTorch test passed"
        else
            print_warning "PyTorch test failed or not applicable"
        fi
    else
        print_info "Skipping deep learning environment test"
    fi
}

# Cleanup function
cleanup() {
    echo ""
    print_info "Cleaning up test environment..."

    # Find and terminate VM processes
    local vm_pids=$(pgrep -f "qemu-system-x86_64.*$IMAGE_FILE")
    if [ -n "$vm_pids" ]; then
        print_info "Terminating VM processes: $vm_pids"
        echo "$vm_pids" | xargs kill -TERM 2>/dev/null
        sleep 3
        echo "$vm_pids" | xargs kill -KILL 2>/dev/null
    fi

    # Clean temporary files in tmp directory
    if [ -d "$TMP_DIR" ]; then
        rm -f "$TMP_DIR"/monitor-*.sock "$TMP_DIR"/vm-*.pid "$TMP_DIR"/vm_output.log
        print_info "Cleaned temporary files from $TMP_DIR"
    fi
}

# Main function
main() {
    print_step "Starting Complete Image Test"

    # Convert relative image path to absolute path before changing directory
    if [[ "$IMAGE_FILE" != /* ]]; then
        # If it's a relative path, convert to absolute path based on current working directory
        IMAGE_FILE="$(cd "$(dirname "$IMAGE_FILE")" 2>/dev/null && pwd)/$(basename "$IMAGE_FILE")" || IMAGE_FILE="$(pwd)/$IMAGE_FILE"
    fi

    print_info "Test Parameters:"
    print_info "  - Image file: $IMAGE_FILE"
    print_info "  - Username: $USERNAME"
    print_info "  - Hostname: $HOSTNAME"
    print_info "  - SSH port: $SSH_PORT"

    # Set cleanup trap
    trap cleanup EXIT INT TERM

    # Enter script directory
    cd "$SCRIPT_DIR" || {
        print_error "Cannot enter script directory: $SCRIPT_DIR"
        exit 1
    }

    # Execute test steps
    if ! find_image_file; then
        exit 1
    fi

    if ! generate_cloud_init; then
        exit 1
    fi

    if ! start_vm; then
        exit 1
    fi

    if ! test_ssh; then
        exit 1
    fi

    # Optional deep learning test
    test_deep_learning

    print_step "Test Complete"
    print_success "All basic tests passed!"
    print_info ""
    print_info "Connection info:"
    print_info "  ssh -p $SSH_PORT $USERNAME@localhost"
    print_info ""
    print_info "VM will remain running for manual testing if needed"
    print_info "Press Ctrl+C to exit and cleanup environment"

    # Wait for user interrupt
    echo ""
    echo "Press Ctrl+C to exit..."
    while true; do
        sleep 60
    done
}

# Check dependencies
check_dependencies() {
    local missing_deps=()

    for cmd in qemu-system-x86_64 ssh nc ss; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Please install missing packages"
        exit 1
    fi
}

# Run main program
check_dependencies
main "$@"
