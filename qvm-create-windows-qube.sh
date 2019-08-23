#!/bin/bash

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

minimize_window() {
    window="$1"
    id="$(xwininfo -root -tree | grep -w "$window" | awk '{ print $1 }')"
    xdotool windowminimize "$id" &> /dev/null
}

usage() {
    echo "Usage: $0 [options] <name>"
    echo "  -h, --help"
    echo "  -c, --count <number> Number of Windows qubes with given basename desired"
    echo "  -n, --netvm <netvm> NetVM for Windows to use (default: sys-firewall)"
    echo "  -b, --background Installation process will happen in a minimized window"
    echo "  -m, --module <modules> Comma-separated list of modules to pre-install"
    echo "  -i, --iso <file> Windows ISO to automatically install and setup (default: Win7_Pro_SP1_English_x64.iso)"
    echo "  -a, --answer-file <xml file> Settings for Windows installation (default: windows-7.xml)"
}

# Option strings
short="hc:n:bm:i:a:"
long="help,count:,netvm:,background,module:,iso:,answer-file:"

# Read options
if ! opts=$(getopt --options=$short --longoptions=$long --name "$0" -- "$@"); then
    exit 1
fi
eval set -- "$opts"

# Set defaults
count="1"
netvm="sys-firewall"
iso="Win7_Pro_SP1_English_x64.iso"
answer_file="windows-7.xml"

# Put options into variables
while true; do
    case "$1" in
        -h | --help)
            usage
            exit
            ;;
        -c | --count)
            count="$2"
            shift 2
            ;;
	-n | --netvm)
            netvm="$2"
            shift 2
            ;;
        -b | --background)
            background="true"
            shift
            ;;
        -m | --module)
            module="$2"
            shift 2
            ;;
        -i | --iso)
            iso="$2"
            shift 2
            ;;
        -a | --answer_file)
            answer_file="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
    esac
done

# Handle postitional arguments
if [ $# != 1 ]; then
    usage >&2
    exit 1
fi
name="$1"

# Validate name
if qvm-check "$name" &> /dev/null; then
    echo -e "${RED}[!]${NC} Qube $name already exists" >&2
    exit 1
fi

# Validate count
if ! [[ "$count" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}[!]${NC} Count is not a number" >&2
    exit 1
elif [ "$count" -lt 1 ]; then
    echo -e "${RED}[!]${NC} Count should be 1 or more" >&2
    exit 1
fi

# Validate netvm
if ! qvm-check "$netvm" &> /dev/null; then
    echo -e "${RED}[!]${NC} NetVM does not exist: $netvm" >&2
    exit 1
elif [ "$(qvm-prefs "$netvm" provides_network)" != "True" ]; then
    echo -e "${RED}[!]${NC} $netvm is not a NetVM" >&2
    exit 1
fi

resources_vm="windows-mgmt"
resources_dir="$HOME/Documents/qvm-create-windows-qube"

# Validate module
IFS="," read -ra module_arr <<< "$module"
for item in "${module_arr[@]}"; do
    if ! qvm-run -p "$resources_vm" "cd '$resources_dir/modules/$item' || exit 1"; then
        echo -e "${RED}[!]${NC} Module $item does not exist" >&2
        exit 1
    fi
done

# Validate iso
if ! qvm-run -p "$resources_vm" "cd '$resources_dir/media-creation/isos' || exit 1; if ! [ -f '$iso' ]; then exit 1; fi"; then
    echo -e "${RED}[!]${NC} File not found in $resources_vm:$resources_dir/media-creation/isos: $iso" >&2
    exit 1
fi

# Validate answer-file
if ! qvm-run -p "$resources_vm" "cd '$resources_dir/media-creation/answer-files' || exit 1; if ! [ -f '$answer_file' ]; then exit 1; fi"; then
    echo -e "${RED}[!]${NC} File not found in $resources_vm:$resources_dir/media-creation/answer-files: $answer_file" >&2
    exit 1
fi

# Install dependencies
echo -e "${BLUE}[i]${NC} Installing package dependencies on $resources_vm..." >&2
until qvm-run -p "$resources_vm" "cd '$resources_dir' || exit 1; './install-dependencies.sh'" &> /dev/null; do
    echo -e "${RED}[!]${NC} Failed to install dependencies! Retrying in 10 seconds..." >&2
    sleep 10
done

# Put answer file into Windows media
autounattend_iso="$(echo "$iso" | sed 's/\.[^.]*$//')-autounattend.iso"
if ! qvm-run -p "$resources_vm" "cd '$resources_dir/media-creation' || exit 1; if ! [ -f $autounattend_iso ]; then './create-media.sh' 'isos/$iso' 'answer-files/$answer_file'; fi" &> /dev/null; then
    echo -e "${RED}[!]${NC} Failed to create media! Possibly out of disk space? Exiting..." >&2
    exit 1
fi

# Create Windows qube the number of times specified using name as the basename if creating more than 1
current_name="$name"
for (( counter = 1; counter <= count; counter++ )); do
    if [ "$count" -gt 1 ]; then
        current_name="$name-$counter"

	# If qube with that number already exists, keep incrementing until one that does not exist is found
	i=0
	while qvm-check "$current_name" &> /dev/null; do
            ((i++))
	    current_name="$name-$i"
        done
    fi
    
    echo -e "${BLUE}[i]${NC} Starting creation of $current_name"
    qvm-create --class StandaloneVM --label red "$current_name"
    qvm-prefs "$current_name" virt_mode hvm
    qvm-prefs "$current_name" memory 400
    qvm-prefs "$current_name" maxmem 400
    qvm-prefs "$current_name" kernel ''
    qvm-features "$current_name" video-model cirrus
    qvm-volume extend "$current_name":root 30g
    qvm-prefs "$current_name" netvm "$netvm"

    echo -e "${BLUE}[i]${NC} Commencing first part of Windows installation process..." >&2
    until qvm-start --cdrom "$resources_vm:$resources_dir/media-creation/$autounattend_iso" "$current_name"; do
        echo -e "${RED}[!]${NC} Failed to start $current_name! Retrying in 10 seconds..." >&2
        sleep 10
    done
    if [ "$background" == "true" ]; then
        until minimize_window "$current_name"; do
            sleep 0.1
        done
    fi

    # Waiting for first part of Windows installation process to finish...
    sleep 3
    while qvm-check --running "$current_name" &> /dev/null; do sleep 1; done

    echo -e "${BLUE}[i]${NC} Commencing second part of Windows installation process..." >&2
    qvm-features --unset "$current_name" video-model
    until qvm-start "$current_name"; do
        echo -e "${RED}[!]${NC} Failed to start $current_name! Retrying in 10 seconds..." >&2
        sleep 10
    done
    if [ "$background" == "true" ]; then
        until minimize_window "$current_name"; do
            sleep 0.1
        done
    fi

    # Waiting for second part of Windows installation process to finish...
    sleep 3
    while qvm-check --running "$current_name" &> /dev/null; do sleep 1; done

    echo -e "${BLUE}[i]${NC} Setting up Auto Tools..." >&2
    # Not not used because once QWT is installed it configures the networking automatically but still included for manual running (for testing)
    ip="$(qvm-prefs "$current_name" ip)"
    qvm-run -p "$resources_vm" "cd '$resources_dir/auto-tools/auto-tools' || exit 1; sed -i 's/^netsh interface ipv4 set address \"Local Area Connection\" static .*$/netsh interface ipv4 set address \"Local Area Connection\" static $ip 255.255.0.0 10.137.0.8/' 'connect-to-network.bat'"
    
    # Process modules
    enabled_modules_file="enabled"
    qvm-run -p "$resources_vm" "cd '$resources_dir/auto-tools/auto-tools/modules' || exit 1; truncate -s 0 $enabled_modules_file"
    for item in "${module_arr[@]}"; do
        qvm-run -p "$resources_vm" "cd '$resources_dir/auto-tools/auto-tools/modules' || exit 1; echo $item >> $enabled_modules_file"
        qvm-run -p "$resources_vm" "cd '$resources_dir/modules/$item' || exit 1; ./run.sh"
    done

    # Pack latest QWT into Auto Tools
    qvm-run -p "$resources_vm" "cat > '$resources_dir/qubes-windows-tools/qubes-windows-tools.iso'" < "/usr/lib/qubes/qubes-windows-tools.iso"
    qvm-run -p "$resources_vm" "cd '$resources_dir/qubes-windows-tools' || exit 1; './unpack-qwt-iso.sh'"

    # Create Auto Tools Media
    qvm-run -p "$resources_vm" "cd '$resources_dir/auto-tools' || exit 1; './create-media.sh'" &> /dev/null
    
    echo -e "${BLUE}[i]${NC} Starting Windows with Auto Tools..." >&2
    qvm-prefs "$current_name" memory 1536
    qvm-prefs "$current_name" maxmem 1536
    until qvm-start --cdrom "$resources_vm:$resources_dir/auto-tools/auto-tools.iso" "$current_name"; do
        echo -e "${RED}[!]${NC} Failed to start $current_name! Retrying in 10 seconds..." >&2
        sleep 10
    done
    if [ "$background" == "true" ]; then
        until minimize_window "$current_name"; do
            sleep 0.1
        done
    fi

    # Waiting for modules and updates to install...
    sleep 3
    while qvm-check --running "$current_name" &> /dev/null; do sleep 1; done

    echo -e "${BLUE}[i]${NC} Installing Qubes Windows Tools..." >&2
    until qvm-start --cdrom "$resources_vm:$resources_dir/auto-tools/auto-tools.iso" "$current_name"; do
        echo -e "${RED}[!]${NC} $current_name failed to start! Retrying in 10 seconds..." >&2
        sleep 10
    done
    if [ "$background" == "true" ]; then
        until minimize_window "$current_name"; do
            sleep 0.1
        done
    fi

    # Waiting for Qubes Windows Tools to shutdown computer automatically after install...
    sleep 3
    while qvm-check --running "$current_name" &> /dev/null; do sleep 1; done

    echo -e "${BLUE}[i]${NC} Booting up then shutting back down to complete setup of Qubes Windows Tools..." >&2
    qvm-start "$current_name"
    if [ "$background" == "true" ]; then
        until minimize_window "$current_name"; do
            sleep 0.1
        done
    fi
    # Need another one because of the new window created when QWT makes Windows adapt to the size of the monitor
    sleep 10
    if [ "$background" == "true" ]; then
        until minimize_window "$current_name"; do
            sleep 0.1
        done
    fi
    sleep 45
    qvm-shutdown "$current_name"
done

echo -e "${GREEN}[+]${NC} Completed successfully!"
