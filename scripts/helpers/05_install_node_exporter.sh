#!/bin/bash

NODE_EXPORTER_REPO=${NODE_EXPORTER_REPO:-"https://github.com/prometheus/node_exporter/releases/download"}
NODE_EXPORTER_VERSION=${NODE_EXPORTER_VERSION:-"1.6.1"}

setup_node_exporter_binary() {
    # Check if node_exporter binary exists
    if command -v node_exporter &>/dev/null; then
        echo "node_exporter binary already exists."
        return
    fi

    # Download node_exporter
    wget "${NODE_EXPORTER_REPO}/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

    # Extract node_exporter
    tar -xzvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

    # Move node_exporter binary
    sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin

    # Cleanup
    rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64
}

setup_node_exporter_systemd() {
    # Check if node_exporter systemd service is active
    if systemctl is-active --quiet node_exporter.service; then
        echo "node_exporter is already installed and active."
        return
    fi

    # Check if node_exporter systemd service exists
    if [ -f /etc/systemd/system/node_exporter.service ]; then
        echo "node_exporter systemd service already exists."
    else
        # Create user and group for node_exporter
        sudo useradd --system node_exporter
        sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

        # Create systemd service
        cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOF
    fi

    # Reload systemd and start node_exporter service
    sudo systemctl daemon-reload
    sudo systemctl enable node_exporter
    sudo systemctl start node_exporter
}

install_node_exporter() {
    setup_node_exporter_binary
    setup_node_exporter_systemd
    echo "node_exporter installed and added to systemd service."
}
