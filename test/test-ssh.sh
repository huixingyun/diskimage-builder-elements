#!/bin/bash

# Enhanced SSH connection test script
# For diagnosing and testing cloud-init configuration
# Usage: ./test-ssh.sh [ssh_port] [username] [host] [max_attempts] [wait_interval]

# Default parameters
DEFAULT_SSH_PORT="2222"
DEFAULT_USERNAME="testuser"
DEFAULT_HOST="localhost"
DEFAULT_MAX_ATTEMPTS=10
DEFAULT_WAIT_INTERVAL=30

# Parse command line arguments
SSH_PORT="${1:-$DEFAULT_SSH_PORT}"
USERNAME="${2:-$DEFAULT_USERNAME}"
HOST="${3:-$DEFAULT_HOST}"
MAX_ATTEMPTS="${4:-$DEFAULT_MAX_ATTEMPTS}"
WAIT_INTERVAL="${5:-$DEFAULT_WAIT_INTERVAL}"

# Show help information
show_help() {
    echo "🔍 SSH Connection Test Script"
    echo ""
    echo "Usage: $0 [ssh_port] [username] [host] [max_attempts] [wait_interval]"
    echo ""
    echo "Parameters:"
    echo "  ssh_port      - SSH port number (default: $DEFAULT_SSH_PORT)"
    echo "  username      - Username (default: $DEFAULT_USERNAME)"
    echo "  host          - Host address (default: $DEFAULT_HOST)"
    echo "  max_attempts  - Maximum attempt count (default: $DEFAULT_MAX_ATTEMPTS)"
    echo "  wait_interval - Wait interval in seconds (default: $DEFAULT_WAIT_INTERVAL)"
    echo ""
    echo "Examples:"
    echo "  $0                           # Use default parameters"
    echo "  $0 2223                      # Specify SSH port"
    echo "  $0 2222 ubuntu               # Specify port and username"
    echo "  $0 2222 testuser localhost 5 15  # Specify all parameters"
    echo ""
}

# Check for help request
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

echo "🔍 Enhanced cloud-init configuration test..."
echo "Configuration parameters:"
echo "   - SSH port: $SSH_PORT"
echo "   - Username: $USERNAME"
echo "   - Host: $HOST"
echo "   - Maximum attempts: $MAX_ATTEMPTS"
echo "   - Wait interval per attempt: ${WAIT_INTERVAL} seconds"
echo ""

# Check if virtual machine is running
check_vm_running() {
    if pgrep -f "qemu-system-x86_64.*image.*qcow2" >/dev/null; then
        echo "✅ Virtual machine process is running"
        return 0
    else
        echo "❌ Virtual machine process is not running"
        return 1
    fi
}

# Check if port is open
check_port_open() {
    if nc -z $HOST $SSH_PORT 2>/dev/null; then
        echo "✅ SSH port $SSH_PORT is open"
        return 0
    else
        echo "❌ SSH port $SSH_PORT is not open"
        return 1
    fi
}

# Attempt SSH connection
try_ssh_connection() {
    local attempt=$1
    echo "🔗 Attempt $attempt SSH connection..."

    ssh -o BatchMode=yes \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=15 \
        -o ServerAliveInterval=5 \
        -o ServerAliveCountMax=3 \
        -p $SSH_PORT \
        $USERNAME@$HOST \
        "echo '✅ SSH connection successful!' && \
         echo '🖥️  Hostname:' \$(hostname) && \
         echo '👤 Current user:' \$(whoami) && \
         echo '📅 System time:' \$(date) && \
         echo '🌐 Network interfaces:' && ip addr show | grep 'inet ' | head -3 && \
         echo '📊 System information:' && \
         (lsb_release -a 2>/dev/null | head -3 || cat /etc/os-release | head -3) && \
         echo '💾 Disk usage:' && df -h / | tail -1 && \
         echo '🔐 Cloud-init status:' && \
         (cloud-init status --long 2>/dev/null || echo 'cloud-init status command not available') && \
         echo '📋 Recent cloud-init logs:' && \
         (sudo tail -15 /var/log/cloud-init.log 2>/dev/null | tail -10 || echo 'cloud-init logs not available') && \
         echo '📋 SSH service status:' && \
         (sudo systemctl status ssh 2>/dev/null | head -5 || echo 'SSH status not available') && \
         echo '📋 Setup logs:' && \
         (sudo cat /var/log/setup.log 2>/dev/null || echo 'Setup logs do not exist')"

    return $?
}

# Main test loop
echo "⏳ Starting test loop..."
echo ""

for i in $(seq 1 $MAX_ATTEMPTS); do
    echo "--- Round $i test ($(date)) ---"

    # Check virtual machine status
    if ! check_vm_running; then
        echo "❌ Virtual machine is not running, please start the virtual machine first"
        echo "💡 Tip: Run ./start-test-vm.sh to start the virtual machine"
        exit 1
    fi

    # Check port status
    check_port_open

    # Attempt SSH connection
    if try_ssh_connection $i; then
        echo ""
        echo "🎉 Cloud-init configuration test successful!"
        echo ""
        echo "💡 Connection information:"
        echo "   ssh -p $SSH_PORT $USERNAME@$HOST"
        echo ""
        echo "🔧 For further debugging, you can check:"
        echo "   - /var/log/cloud-init.log (cloud-init logs)"
        echo "   - /var/log/setup.log (custom setup logs)"
        echo "   - systemctl status ssh (SSH service status)"
        exit 0
    else
        echo "❌ Connection attempt $i failed"

        if [ $i -eq $MAX_ATTEMPTS ]; then
            echo ""
            echo "💥 Maximum attempt count reached, test failed"
            echo ""
            echo "🔧 Troubleshooting suggestions:"
            echo "   1. Check virtual machine startup logs for error messages"
            echo "   2. Confirm cloud-init configuration syntax is correct"
            echo "   3. Check if the image supports cloud-init"
            echo "   4. Try increasing memory or CPU resources"
            echo "   5. Check if SSH service is properly installed"
            echo ""
            echo "📋 Current system status:"
            echo "   - Virtual machine processes: $(pgrep -f qemu-system-x86_64 | wc -l)"
            echo "   - Port $SSH_PORT status: $(nc -z $HOST $SSH_PORT && echo 'open' || echo 'closed')"
            exit 1
        else
            echo "⏳ Waiting ${WAIT_INTERVAL} seconds before retry..."
            sleep $WAIT_INTERVAL
        fi
    fi
    echo ""
done
