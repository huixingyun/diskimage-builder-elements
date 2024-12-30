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
ExecStartPre=-bash -c 'source /opt/scripts-install/helpers/00_mount_data.sh && grow_partition "$partition"'
ExecStart=bash -c 'ls "${mount_point}" | head -1'
[Install]
WantedBy=cloud-init.target
EOF

    systemctl daemon-reload
    systemctl enable --now --no-block "${filename}.service"
    echo "trigger mount $mount_point success"
}

grow_partition() {
    local partition="$1"

    # get device from partition
    local device=/dev/$(lsblk -o PKNAME -bnr "${partition}")

    # compare device size and partition size
    local device_size=$(lsblk -o SIZE -bnr "${device}" | head -n 1)
    local partition_size=$(df -B1 "${partition}" | awk 'NR==2 {print $2}')
    local diff_size=$((device_size - partition_size))

    # if diff_size <= 1GB, do nothing
    if [ "$diff_size" -le 1073741824 ]; then
        echo "partition ${partition} will not grow, diff_size=${diff_size}"
        return
    fi

    umount "${partition}" &>/dev/null
    growpart "${device}" 1
    e2fsck -p -f "${partition}"
    resize2fs "${partition}"
    echo "grow partition ${partition} success"
}
