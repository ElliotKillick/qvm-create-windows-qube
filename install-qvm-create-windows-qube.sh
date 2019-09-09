#!/bin/bash

trap 'exit 1' ERR INT

if [ "$(hostname)" != "dom0" ]; then
    echo "This script must be run in Dom0!" >&2
    exit 1
fi

# Create a new AppVM
qvm-create --class AppVM --template fedora-30 --label black windows-mgmt

# Increase storage capacity
qvm-volume extend windows-mgmt:private 20480M

# Clone qvm-create-windows-qube repository
qvm-run -p windows-mgmt 'cd Documents && git clone https://github.com/crazyqube/qvm-create-windows-qube'

# Run the script to download Windows
qvm-run -p windows-mgmt 'cd Documents/qvm-create-windows-qube && ./download-windows.sh'

# Install Qubes Windows Tools
sudo qubes-dom0-update --enablerepo=qubes-dom0-current-testing qubes-windows-tools

# Copy script to Dom0
qvm-run -p windows-mgmt 'cat /home/user/Documents/qvm-create-windows-qube/qvm-create-windows-qube.sh' > qvm-create-windows-qube.sh

# Allow execution of script
chmod +x qvm-create-windows-qube.sh
