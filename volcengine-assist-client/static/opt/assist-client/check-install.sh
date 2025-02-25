#!/usr/bin/env bash
set -e

CURRENT_DIR="$(dirname "$0")"

install() {
    INSTALL_SCRIPT="$CURRENT_DIR/install.sh"
    if [ ! -f "$INSTALL_SCRIPT" ]; then
        echo "Install script not found"
        exit 1
    fi
    bash "$INSTALL_SCRIPT"
}

# check if service is running
SERVICE_NAME="assist-client"
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Service is running"
else
    install
fi
