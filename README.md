# diskimage-builder-elements

Some elements for [diskimage-builder (DIB)](https://docs.openstack.org/diskimage-builder/latest/) to build images.

## requirements

**Host OS Requirements:**

- Ubuntu 22.04 with kernel 5.15.0-141-generic
- Ubuntu 20.04 with kernel 5.4.0-216-generic

Install kernel using the following command:

```sh
sudo apt install linux-image-5.15.0-141-generic linux-headers-5.15.0-141-generic
```

Create a vm for image building:

```sh
./vm.sh
```

After login in vm:

```sh
sudo su
cd /root/build/
```

## build image

```sh
./easy_build.sh image-gpu-mini
```

The image file **image-gpu-mini_YYYYMMDD.qcow2** will be generated in the `output/` directory, with the filename including the build date.

**Notes:**

- `easy_build.sh` takes the configuration filename (without extension) from the `etc/` directory
- `easy_build.sh` will automatically execute `git pull` to update the code
- Automatically creates the `output/` directory to store build results
- Image filename will automatically include date suffix (e.g., `image-gpu-mini_20241225.qcow2`)
- Build logs will be saved in `output/image-gpu-mini.log`

## upload images to OpenStack

> Download "OpenStack RC File" from dashboard, save it as **service-openrc.sh**.

```sh
# Load OpenStack RC file
source ./service-openrc.sh

# Enter output directory
cd output/

# Load upload-image functions
source ../upload-image

# Upload Ubuntu image
image-ubuntu image-gpu-mini_20241225

# Upload CentOS image
image-centos image-name_20241225 7

# Upload Windows image
image-windows image-name_20241225

# Upload data disk image
image-data image-name_20241225
```

**Notes:**

- You need to `source ./upload-image` first to load the functions, then call the corresponding methods
- The `upload-image` script will automatically install `python-openstackclient`
- The script supports multiple image type methods: `image-ubuntu`, `image-centos`, `image-windows`, `image-data`
- Image filename uses the date-suffixed filename generated during build
- The script automatically detects `.qcow2` or `.img` format and sets the appropriate disk format
- Optional configuration files:
  - `image-name.id.txt` - specify image ID
  - `image-name.desc.txt` - set image description

## Local Image Testing

**Note:** All test temporary files (cloud-init configurations, VM logs, etc.) are automatically stored in the `tmp/` directory to keep the workspace clean.

### 1. Complete Testing with Test Scripts

It is recommended to use the provided test scripts for image testing, which support flexible parameter configuration:

#### 1.1 Generate cloud-init Configuration

```sh
# Use default configuration (username: testuser, hostname: test-vm)
./test/generate-configdrive.sh

# Custom configuration
./test/generate-configdrive.sh [username] [hostname] [instance-id]

# Example: custom user and hostname
./test/generate-configdrive.sh ubuntu my-test-vm iid-test01
```

The script will automatically:
- Check and generate SSH key pair (if not exists)
- Generate ConfigDrive format `user_data` and `meta_data.json` configuration files in `tmp/configdrive/`
- Create `tmp/seed.iso` cloud-init data disk

#### 1.2 Start Test Virtual Machine

```sh
# Use default parameters
./test/start-test-vm.sh

# Specify image file
./test/start-test-vm.sh ../output/image-gpu-mini_20241225.qcow2

# Specify all parameters [image_file] [memory_MB] [cpu_cores] [ssh_port]
./test/start-test-vm.sh image.qcow2 8192 8 2223

# Show help information
./test/start-test-vm.sh --help
```

**Default Parameters:**
- Memory: 4096MB
- CPU: 4 cores
- SSH Port: 2222
- Enable KVM hardware acceleration and VirtIO drivers

**QEMU VM Exit Methods:**

```sh
# Method 1: Use QEMU monitor command (recommended)
# Press Ctrl+A, then press C to enter QEMU monitor mode
# At the monitor prompt, type:
(qemu) quit

# Method 2: Keyboard shortcut to exit directly
# Press Ctrl+A, then press X to exit QEMU immediately

# Method 3: Normal shutdown from inside VM (safest)
# SSH login to VM and execute:
sudo shutdown -h now
# or
sudo poweroff

# Method 4: Force exit (only when QEMU is unresponsive)
# In another terminal, find QEMU process and kill it:
ps aux | grep qemu
kill -9 <qemu-pid>
```

#### 1.3 Test SSH Connection and cloud-init

```sh
# Test SSH connection with default parameters
./test/test-ssh.sh

# Specify SSH port
./test/test-ssh.sh 2223

# Specify port and username
./test/test-ssh.sh 2222 ubuntu

# Specify all parameters [ssh_port] [username] [host] [max_attempts] [wait_interval_seconds]
./test/test-ssh.sh 2222 testuser localhost 5 15

# Show help information
./test/test-ssh.sh --help
```

The script will automatically:
- Check if VM process is running
- Test SSH port connectivity
- Attempt SSH connection and collect system information
- Check cloud-init status and logs
- Provide detailed troubleshooting suggestions

#### 1.4 One-Click Complete Testing

For convenience, a complete testing script is provided that automates the entire process:

```sh
# Auto-find today's image and run complete test
./test/test-complete.sh

# Specify image file (path relative to current working directory)
./test/test-complete.sh output/image-gpu-mini_20241225.qcow2

# Specify image, username and hostname
./test/test-complete.sh output/image.qcow2 ubuntu my-vm

# Show help information
./test/test-complete.sh --help
```

**Important Note:** When specifying image file paths, use paths relative to your current working directory (where you run the command), not relative to the script location. The script will automatically convert relative paths to absolute paths.

This script will automatically:
1. Find and verify image files
2. Generate cloud-init configuration
3. Start test VM
4. Test SSH connection and system functionality
5. Optionally test CUDA and PyTorch environment

#### 1.5 GPU and Deep Learning Environment Testing

**CUDA Installation Verification:**

```sh
# Run CUDA test inside VM
ssh -p 2222 testuser@localhost
sudo /root/verify_cuda.sh
```

**PyTorch Environment Testing:**

```sh
# Run PyTorch test inside VM
ssh -p 2222 testuser@localhost
python3 /root/verify_pytorch.py
```

### 2. Manual SSH Login Testing

After the VM starts, you can login with the following command:

```sh
# Use configured user login
ssh -p 2222 testuser@localhost

# If root user public key is configured, can also login directly as root
ssh -p 2222 root@localhost

# If SSH key is not in default location, specify key file
ssh -p 2222 -i ~/.ssh/id_rsa testuser@localhost
```

### 3. Verify cloud-init Configuration Effect

- SSH login, check if user, hostname, etc. are set according to `user_data`
- Check cloud-init logs:
  ```sh
  sudo cat /var/log/cloud-init.log
  sudo cat /var/log/cloud-init-output.log
  ```
- Verify SSH configuration:
  ```sh
  # Check if SSH public key is correctly configured
  cat ~/.ssh/authorized_keys

  # Check SSH service configuration
  sudo cat /etc/ssh/sshd_config | grep -E "(PubkeyAuthentication|PasswordAuthentication)"
  ```

### 4. Test Script Description

Test directory contains the following scripts:

- `generate-configdrive.sh` - Generate ConfigDrive format cloud-init configuration
- `start-test-vm.sh` - Flexible start test VM, support parameter customization
- `test-ssh.sh` - SSH connection test and cloud-init configuration verification
- `test-complete.sh` - One-click complete testing script that automates the entire process
- `verify_cuda.sh` - CUDA installation and functionality verification
- `verify_pytorch.py` - Complete PyTorch environment test

All scripts support `--help` parameter to view detailed usage.
