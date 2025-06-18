#!/bin/bash

setup_disk_partition() {
    local device="$1"
    local partition="${device}1"

    # check if partition exists
    if lsblk -rno NAME "$partition" >/dev/null 2>&1; then
        echo "partition $partition exist"
        return
    fi

    # create partition
    echo "partition $partition not exist, creating..."
    # Using parted instead of fdisk for more than 2TB partition
    #   mklabel label-type
    #   mkpart [part-type name fs-type] start end
    parted --align optimal --script "$device" -- mklabel gpt mkpart primary ext4 0% 100%

    # Wait for partition to be created
    while ! lsblk -rno NAME "$partition" >/dev/null 2>&1; do
        sleep 1
    done
    echo "partition $partition created"
}

systemd_mount_partition() {
    local partition="$1"
    local mount_point="$2"

    # check if partition is ext4 format
    while ! blkid -s TYPE -o value "$partition" | grep -q ext4; do
        if ! mkfs.ext4 "$partition"; then
            sleep 1
            continue
        fi
        echo "format $partition to ext4 success"
    done

    # e.g. mount_point=/disk/sdb1 -> filename=disk-sdb1
    local filename="${mount_point//\//-}"
    filename="${filename#-}"

    # create mount point directory
    mkdir -p "$mount_point"

    # create systemd mount unit file
    cat <<EOF >"/etc/systemd/system/${filename}.mount"
[Unit]
Description=Mount disk $partition to $mount_point
[Mount]
What=$partition
Where=$mount_point
Type=ext4
Options=defaults
EOF
    # create systemd automount unit file
    cat <<EOF >"/etc/systemd/system/${filename}.automount"
[Unit]
Description=Auto mount $mount_point
Requires=cloud-init.target
[Automount]
Where=$mount_point
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl disable "${filename}.mount"
    systemctl enable "${filename}.automount"
    # if .automount not start and .mount is started
    if ! systemctl is-active --quiet "${filename}.automount" && systemctl is-active --quiet "${filename}.mount"; then
        systemctl stop "${filename}.mount"
    fi
    systemctl start "${filename}.automount"
    echo "mount $partition to $mount_point success"
}

trigger_mount_service() {
    local partition="$1"
    local mount_point="$2"

    # e.g. mount_point=/disk/sdb1 -> filename=disk-sdb1
    local filename="${mount_point//\//-}"
    filename="${filename#-}"

    # exec stat once on $mount_point
    # this must exec after cloud-init.target
    cat <<EOF >"/etc/systemd/system/${filename}.service"
[Unit]
Description=grow partition "$partition" and trigger mount "$mount_point"
After=cloud-final.service
[Service]
Type=oneshot
ExecStartPre=-bash -c 'source /opt/scripts-install/helpers/00_mount_data.sh && grow_partition "$partition" "$mount_point"'
ExecStart=bash -c 'ls "${mount_point}" | head -1'
[Install]
WantedBy=cloud-init.target
EOF

    systemctl daemon-reload
    systemctl enable --now --no-block "${filename}.service"
    echo "trigger mount $mount_point success"
}

grow_partition() {
    set -euo pipefail

    local partition="$1"
    local mount_point="${2:-"/root/data"}"

    # 1. Get device and filesystem size without mounting
    local device="/dev/$(lsblk -o PKNAME -bnr "${partition}")"
    local device_size=$(lsblk -o SIZE -bnr "${device}" | head -n 1)

    # Get filesystem size using dumpe2fs
    local block_count=$(dumpe2fs -h "${partition}" 2>/dev/null | awk -F: '/Block count/ {print $2}' | tr -d '[:space:]')
    local block_size=$(dumpe2fs -h "${partition}" 2>/dev/null | awk -F: '/Block size/ {print $2}' | tr -d '[:space:]')

    if [[ ! "$block_count" =~ ^[0-9]+$ ]] || [[ ! "$block_size" =~ ^[0-9]+$ ]]; then
        echo "Failed to get filesystem info from ${partition}, it may not be an ext4 filesystem or is corrupted. Skipping grow."
        return 0
    fi
    local fs_size=$((block_count * block_size))
    local diff_size=$((device_size - fs_size))

    if [ "$diff_size" -le 1073741824 ]; then
        echo "Filesystem on ${partition} will not grow, size difference is ${diff_size} bytes."
        return 0
    fi

    # 2. Stop automount and unmount if necessary
    local filename="${mount_point//\//-}"
    filename="${filename#-}"

    echo "Stopping automount for ${mount_point}..."
    systemctl stop "${filename}.automount"
    if mountpoint -q "$mount_point"; then
        echo "Unmounting ${mount_point}..."
        umount "${mount_point}"
    fi

    # 3. Wait for device to be free
    local count=0
    while lsof "${partition}" >/dev/null 2>&1; do
        if [ $count -ge 10 ]; then
            echo "Device ${partition} is still in use after 10s, aborting."
            lsof "${partition}"
            systemctl start "${filename}.automount"
            return 1
        fi
        sleep 1
        count=$((count + 1))
    done

    # 4. Grow partition and filesystem
    echo "Growing partition ${partition}..."

    # Use flock on the partition device to prevent race conditions with udev.
    (
        flock -x 9
        set -e
        echo "Lock acquired on ${partition}..."
        growpart "${device}" 1 || true
        e2fsck -p -f "${partition}" && resize2fs "${partition}"
        echo "Grow operation completed, releasing lock."
    ) 9>"${partition}"

    local ret=$?

    # 5. Start automount
    echo "Starting automount for ${mount_point}..."
    systemctl start "${filename}.automount"

    if [ "$ret" -eq 0 ]; then
        echo "grow partition ${partition} success"
    else
        echo "grow partition ${partition} failed with exit code $ret"
    fi
    return "$ret"
}
