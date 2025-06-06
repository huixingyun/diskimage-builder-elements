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

### 1. Launch Image with QEMU

Assuming you have generated the image file `image-gpu-mini.qcow2`, you can start it with the following command:

```sh
qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -drive file=image-gpu-mini.qcow2,format=qcow2 \
  -net nic -net user,hostfwd=tcp::2222-:22 \
  -nographic
```

- `-m 2048`: Allocate 2GB memory
- `-smp 2`: Allocate 2 CPUs
- `-drive file=...`: Specify image file
- `-net user,hostfwd=tcp::2222-:22`: Forward local port 2222 to VM port 22
- `-nographic`: Display serial output in terminal

### 2. SSH Login Testing

After the VM starts, you can login with the following command (username and password depend on image configuration):

```sh
ssh -p 2222 <username>@localhost
```

### 3. Test cloud-init Process

1. **Use test script:**

   ```sh
   # Generate cloud-init configuration and ISO image
   ./test/generate-cloudinit-config.sh [username] [hostname] [instance-id]

   # Example: use default configuration
   ./test/generate-cloudinit-config.sh

   # Example: custom configuration
   ./test/generate-cloudinit-config.sh myuser my-vm iid-test01
   ```

   The script will automatically:

   - Check and generate SSH key pair (if not exists)
   - Generate `user-data` and `meta-data` configuration files
   - Create `seed.iso` cloud-init data disk

2. **Start test VM:**

   ```sh
   # Start with default configuration
   ./test/start-test-vm.sh

   # Start with custom configuration
   ./test/start-test-vm.sh [image-file] [memory-MB] [cpu-count] [ssh-port]

   # Example: specify image and configuration
   ./test/start-test-vm.sh image-gpu-mini.qcow2 4096 4 2222
   ```

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

   # Method 4: Force exit if QEMU is unresponsive
   # In another terminal, find QEMU process and kill it:
   ps aux | grep qemu
   kill -9 <qemu-pid>
   ```

   **Notes:**

   - Recommended to use Method 3 (shutdown from inside VM) or Method 1 (monitor quit) for safe exit
   - Methods 2 and 4 may cause VM filesystem corruption, use only when necessary
   - In `-nographic` mode, all input is sent to the VM, use `Ctrl+A` to switch to QEMU control mode

3. **Login with SSH public key:**

   After the VM starts, you can login directly using SSH keys:

   ```sh
   # Login with configured user
   ssh -p 2222 testuser@localhost

   # If root user public key is configured, you can also login as root directly
   ssh -p 2222 root@localhost

   # If SSH key is not in default location, specify key file
   ssh -p 2222 -i ~/.ssh/id_rsa testuser@localhost
   ```

4. **Verify cloud-init effectiveness:**

   - After SSH login, check if user, hostname, etc. are set according to `user-data`.
   - View cloud-init logs:
     ```sh
     sudo cat /var/log/cloud-init.log
     sudo cat /var/log/cloud-init-output.log
     ```
   - Verify SSH configuration:

     ```sh
     # Check if SSH public key is configured correctly
     cat ~/.ssh/authorized_keys

     # Check SSH service configuration
     sudo cat /etc/ssh/sshd_config | grep -E "(PubkeyAuthentication|PasswordAuthentication)"
     ```
