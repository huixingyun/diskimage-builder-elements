# Test Scripts for diskimage-builder-elements

This directory contains test scripts for validating built images and their functionality.

**Note:** All temporary files generated during testing (cloud-init configurations, logs, etc.) are stored in the `tmp/` directory to keep the workspace clean.

## Quick Start

For the fastest testing experience, use the complete testing script:

```bash
# Auto-find today's image and run complete test
./test-complete.sh

# Specify a specific image file (path relative to project root)
./test-complete.sh ../output/image-gpu-mini_20241225.qcow2

# Get help
./test-complete.sh --help
```

**Path Usage:** When running scripts from within the `test/` directory, image paths should be relative to the test directory. When running from project root, paths should be relative to project root.

## Individual Test Scripts

### 1. `generate-configdrive.sh`
Generates ConfigDrive format cloud-init configuration files.

```bash
# Use default configuration (username: testuser, hostname: test-vm)
./generate-configdrive.sh

# Custom configuration
./generate-configdrive.sh [username] [hostname] [instance-id]

# Example
./generate-configdrive.sh ubuntu my-test-vm iid-test01
```

**Output:**
- `../tmp/configdrive/` directory with cloud-init configuration
- `../tmp/seed.iso` - Cloud-init data disk

### 2. `start-test-vm.sh`
Starts a QEMU virtual machine with flexible parameters.

```bash
# Use default parameters (4GB RAM, 4 CPUs, SSH port 2222)
./start-test-vm.sh

# Specify image file
./start-test-vm.sh ../output/image-gpu-mini.qcow2

# Specify all parameters [image] [memory_MB] [cpu_cores] [ssh_port]
./start-test-vm.sh image.qcow2 8192 8 2223

# Get help
./start-test-vm.sh --help
```

**VM Exit Methods:**
- `Ctrl+A` then `C`, type `quit` (recommended)
- `Ctrl+A` then `X` (immediate exit)
- Inside VM: `sudo shutdown -h now`

### 3. `test-ssh.sh`
Tests SSH connectivity and collects system information.

```bash
# Test with default parameters (port 2222, user testuser)
./test-ssh.sh

# Specify SSH port
./test-ssh.sh 2223

# Specify all parameters [port] [username] [host] [max_attempts] [wait_seconds]
./test-ssh.sh 2222 ubuntu localhost 5 15

# Get help
./test-ssh.sh --help
```

**Features:**
- Checks VM process status
- Tests SSH port connectivity  
- Attempts SSH connection with detailed system info
- Shows cloud-init status and logs
- Provides troubleshooting suggestions

### 4. `test-complete.sh`
One-click complete testing that automates the entire process.

```bash
# Auto-find image and run complete test
./test-complete.sh

# Specify parameters [image] [username] [hostname] [memory] [cpus] [port]
./test-complete.sh image.qcow2 ubuntu my-vm 8192 8 2223

# Get help
./test-complete.sh --help
```

**Process:**
1. Find and verify image files
2. Generate cloud-init configuration
3. Start test VM in background
4. Test SSH connection and system functionality
5. Optional CUDA and PyTorch environment testing
6. Keep VM running for manual testing

### 5. `verify_cuda.sh`
CUDA installation and functionality verification (run inside VM).

```bash
# SSH into VM and run CUDA test
ssh -p 2222 testuser@localhost
sudo ./verify_cuda.sh
```

**Checks:**
- NVIDIA GPU detection
- NVIDIA driver status
- CUDA toolkit installation
- CUDA functionality test

### 6. `verify_pytorch.py`
Complete PyTorch environment testing (run inside VM).

```bash
# SSH into VM and run PyTorch test
ssh -p 2222 testuser@localhost
python3 ./verify_pytorch.py
```

**Tests:**
- PyTorch import and version
- Basic tensor operations
- CUDA availability and GPU computation
- Simple neural network training
- Data loading functionality

### 7. `cleanup.sh`
Cleans up all test temporary files in the `tmp/` directory.

```bash
# Clean all test temporary files
./cleanup.sh
```

**Cleans:**
- Cloud-init configuration files (`configdrive/`, `seed.iso`)
- VM runtime files (`monitor-*.sock`, `vm-*.pid`, `vm_output.log`)
- Stops any running QEMU VM processes

**Note:** Image files in `tmp/` are preserved and not deleted.

## Testing Workflow

### Basic Image Testing
```bash
# Step 1: Generate cloud-init config
./generate-configdrive.sh

# Step 2: Start VM
./start-test-vm.sh ../output/image-gpu-mini.qcow2

# Step 3: Test SSH (in another terminal)
./test-ssh.sh
```

### Quick Complete Testing
```bash
# One command for everything
./test-complete.sh ../output/image-gpu-mini.qcow2
```

### GPU/Deep Learning Testing
```bash
# After SSH connection is established
ssh -p 2222 testuser@localhost

# Test CUDA
sudo /root/verify_cuda.sh

# Test PyTorch  
python3 /root/verify_pytorch.py
```

## Dependencies

Required tools on the host system:
- `qemu-system-x86_64` - Virtual machine emulation
- `ssh` - SSH client
- `nc` (netcat) - Network connectivity testing
- `ss` - Socket statistics
- `genisoimage` or `mkisofs` - ISO creation

Install on Ubuntu/Debian:
```bash
sudo apt-get install qemu-kvm qemu-utils openssh-client netcat-openbsd iproute2 genisoimage
```

## Troubleshooting

### VM Won't Start
- Check if image file exists and is accessible
- Ensure SSH port is not already in use
- Verify KVM is available: `ls /dev/kvm`
- Try without KVM acceleration

### SSH Connection Fails
- Wait longer for VM to fully boot
- Check if VM process is running: `ps aux | grep qemu`
- Verify port forwarding: `ss -ltn | grep :2222`
- Check cloud-init logs inside VM

### Cloud-init Issues
- Verify `seed.iso` was created properly
- Check cloud-init configuration syntax
- Review VM console output for errors
- Check `/var/log/cloud-init.log` inside VM

All scripts support `--help` for detailed usage information. 