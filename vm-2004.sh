#!/bin/bash
set -e

instance_name=imgbuild2004

cd "$(dirname "$0")"

# if multipass not installed, install it
if ! command -v multipass &> /dev/null; then
  sudo snap install multipass --classic
fi

# if imgbuild not found, create it
if ! multipass list | grep -q $instance_name; then
  multipass launch \
    --name $instance_name \
    --cpus 4 --memory 8G --disk 80G \
    --mount $(pwd):/root/build \
    --cloud-init cloud-init.yaml \
    20.04
fi

# attack the imgbuild vm
multipass exec $instance_name -- sudo -i
