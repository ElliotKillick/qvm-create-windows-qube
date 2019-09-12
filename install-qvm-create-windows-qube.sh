#!/bin/bash

trap 'exit' ERR

if [ "$(hostname)" != "dom0" ]; then
    echo "This script must be run in Dom0!" >&2
    exit 1
fi

resources_vm="windows-mgmt"
resources_dir="/home/user/Documents/qvm-create-windows-qube"

# Create a new AppVM
qvm-create --class AppVM --template fedora-30 --label black "$resources_vm"

# Increase storage capacity
qvm-volume extend "$resources_vm":private 20480M

# Clone qvm-create-windows-qube repository
qvm-run -p "$resources_vm" "cd /home/user/Documents && git clone https://github.com/crazyqube/qvm-create-windows-qube"

# Run the script to download Windows
qvm-run -p "$resources_vm" "cd '$resources_dir' && ./download-windows.sh"

# Install Qubes Windows Tools
sudo qubes-dom0-update --enablerepo=qubes-dom0-current-testing qubes-windows-tools

# Copy script into Dom0
qvm-run -p "$resources_vm" "cat '$resources_dir/qvm-create-windows-qube.sh' > qvm-create-windows-qube.sh"

# Allow execution of script
chmod +x qvm-create-windows-qube.sh
