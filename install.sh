#!/bin/bash

trap 'exit' ERR

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
    echo "Usage: ${0} [NetVM]"
    echo ""
    echo "Setup resources qube, download Windows, install package dependencies in template, install Qubes Windows Tools and finally copy qvm-create-windows-qube.sh to Dom0"
    echo ""
    echo "The optional NetVM paramater is the NetVM for use in downloading the project and Windows media (default: sys-firewall if no global default is set)"
}

for arg in "$@"; do
    if [ "$arg" == "-h" ] ||  [ "$arg" == "--help" ]; then
        usage
        exit
    fi
done

netvm="$1"

# Validate this is Dom0
if [ "$(hostname)" != "dom0" ]; then
    echo -e "${RED}[!]${NC} This script must be run in Dom0" >&2
    exit 1
fi

# Validate netvm
if [ "$netvm" ]; then
    if ! qvm-check "$netvm" &> /dev/null; then
        echo -e "${RED}[!]${NC} NetVM does not exist: $netvm" >&2
        exit 1
    elif [ "$(qvm-prefs "$netvm" provides_network)" != "True" ]; then
        echo -e "${RED}[!]${NC} Not a NetVM: $netvm" >&2
        exit 1
    fi
fi

resources_qube="windows-mgmt"
resources_dir="/home/user/Documents/qvm-create-windows-qube"
template="$(qubes-prefs default_template)"

echo -e "${BLUE}[i]${NC} Creating $resources_qube..." >&2
qvm-create --class AppVM --template "$template" --label black "$resources_qube"

echo -e "${BLUE}[i]${NC} Increasing storage capacity of $resources_qube..." >&2
qvm-volume extend "$resources_qube:private" 20480MiB

# Temporarily enable networking
# If no global default NetVM has already been set (upon creation of qube)
if ! [ "$(qvm-prefs "$resources_qube" netvm)" ]; then
    if [ "$netvm" ]; then
        resources_qube_netvm="$netvm"
    else
        resources_qube_netvm="sys-firewall"
    fi

    echo -e "${BLUE}[i]${NC} Temporarily enabling networking of $resources_qube with $resources_qube_netvm..." >&2
    qvm-prefs "$resources_qube" netvm "$resources_qube_netvm"
fi

echo -e "${BLUE}[i]${NC} Cloning qvm-create-windows-qube Github repository..." >&2
qvm-run -p "$resources_qube" "cd ${resources_dir%/*} && git clone https://github.com/elliotkillick/qvm-create-windows-qube"

echo -e "${BLUE}[i]${NC} Please check for a good GPG signature (Verify it out-of-band if necessary)..." >&2
qvm-run -q "$resources_qube" "gpg --keyserver keys.openpgp.org --recv-keys 018FB9DE6DFA13FB18FB5552F9B90D44F83DD5F2"
qvm-run -p "$resources_qube" "cd '$resources_dir' && git verify-commit HEAD"

echo -e "${BLUE}[i]${NC} Downloading Windows..." >&2
qvm-run -p "$resources_qube" "cd '$resources_dir' && ./download-windows.sh"

echo -e "${BLUE}[i]${NC} Air gapping $resources_qube..." >&2
qvm-prefs "$resources_qube" netvm ""

echo -e "${BLUE}[i]${NC} Installing package dependencies in $template..." >&2
packages="genisoimage"
qvm-run -p "$template" "if command -v dnf &> /dev/null; then sudo dnf -y install $packages; else sudo apt-get -y install $packages; fi"

echo -e "${BLUE}[i]${NC} Shutting down $resources_qube and $template so the root filesystem can sync up..." >&2
# qvm-run always returns 1 probably due to not getting a response in time before the qube shuts down; as a result force always return 0 to not trigger the ERR trap
qvm-run -q "$resources_qube" "sudo shutdown now" || true
qvm-run -q "$template" "sudo shutdown now" || true

echo -e "${BLUE}[i]${NC} Installing Qubes Windows Tools..." >&2
sudo qubes-dom0-update -y --enablerepo=qubes-dom0-current-testing qubes-windows-tools

echo -e "${BLUE}[i]${NC} Copying qvm-create-windows-qube.sh to Dom0..." >&2
qvm-run -p --filter-escape-chars --no-colour-output "$resources_qube" "cat '$resources_dir/qvm-create-windows-qube.sh'" > qvm-create-windows-qube.sh

# Allow execution of script
chmod +x qvm-create-windows-qube.sh

echo -e "${GREEN}[+]${NC} Installation complete!"
