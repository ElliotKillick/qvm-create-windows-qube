#!/bin/bash

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

wait_for_shutdown() {
    name="$1"
    is_boot="$2"
    # There is a small delay upon booting a qube before qvm-check will detect it as running
    if [ "$is_boot" == "true" ]; then
        sleep 5
    fi
    while qvm-check --running "$name" &> /dev/null; do
        sleep 1
    done
}

get_window_id() {
    name="$1"
    xdotool search --name "$name" 2> /dev/null
}

is_window_minimized() {
    name="$1"
    id="$(get_window_id "$name")"
    if [ "$id" ]; then
        if [ "$(xwininfo -id "$id" | grep "Map State: " | awk '{ print $3 }')" == "IsUnMapped" ]; then
            return
        fi
    fi

    false
}

minimize_window() {
    name="$1"
    id="$(get_window_id "$name")"
    xdotool windowminimize "$id" &> /dev/null
}

usage() {
    echo "Usage: $0 [options] <name>"
    echo "  -h, --help"
    echo "  -c, --count <number> Number of Windows qubes with given basename desired"
    echo "  -n, --netvm <qube> NetVM for Windows to use (default: sys-firewall)"
    echo "  -b, --background Installation process will happen in a minimized window"
    echo "  -p, --packages <packages> Comma-separated list of packages to pre-install (see available packages at: https://chocolatey.org/packages)"
    echo "  -d, --disable-updates Disables installing of future updates (automatic reboots are disabled either way)"
    echo "  -i, --iso <file> Windows ISO to automatically install and setup (default: Win7_Pro_SP1_English_x64.iso)"
    echo "  -a, --answer-file <xml file> Settings for Windows installation (default: windows-7.xml)"
}

# Option strings
short="hc:n:bp:di:a:"
long="help,count:,netvm:,background,packages:,disable-updates,iso:,answer-file:"

# Read options
if ! opts=$(getopt --options=$short --longoptions=$long --name "$0" -- "$@"); then
    exit 1
fi
eval set -- "$opts"

# Set defaults
count="1"
netvm=""
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
        -p | --packages)
            packages="$2"
            shift 2
            ;;
        -d | --disable-updates)
            disable_updates="true"
            shift
            ;;
        -i | --iso)
            iso="$2"
            shift 2
            ;;
        -a | --answer-file)
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
if [ "$netvm" != "" ]; then
    if ! qvm-check "$netvm" &> /dev/null; then
        echo -e "${RED}[!]${NC} NetVM does not exist: $netvm" >&2
        exit 1
    elif [ "$(qvm-prefs "$netvm" provides_network)" != "True" ]; then
        echo -e "${RED}[!]${NC} $netvm is not a NetVM" >&2
        exit 1
    fi
fi

resources_vm="windows-mgmt"
resources_dir="/home/user/Documents/qvm-create-windows-qube"

# Validate packages
if [ "$packages" != "" ]; then
    if [ "$netvm" != "" ]; then
        if [ "$netvm" != "sys-whonix" ] && [ "$(qvm-prefs "$resources_vm" netvm)" != "sys-whonix" ]; then
            IFS="," read -ra package_arr <<< "$packages"
            for package in "${package_arr[@]}"; do
                if ! qvm-run -p "$resources_vm" "if [ \"\$(curl -so /dev/null -w '%{http_code}' \"https://chocolatey.org/api/v2/package/$package\")\" == 404 ]; then exit 1; fi"; then
                    echo -e "${RED}[!]${NC} Package $package not found" >&2
                    exit 1
                fi
            done
        else
            echo -e "${RED}[!]${NC} Cannot install Chocolatey packages because they use Cloudflare to indiscriminately block requests from curl/PowerShell over Tor. Websites may defend this practice by saying that the majority of Tor requests are malicious. However, this is a faulty comparision because just like with email or generally any other part of the internet these bad requests are made by a few bad apples that take more than their fair share of resources. To make a change, please visit https://chocolatey.org/contact and submit a blocked IP report refrencing Tor and this project." >&2
            exit 1
        fi
    else
        echo -e "${RED}[!]${NC} A NetVM must be configured to use packages" >&2
        exit 1
    fi
fi

# Validate iso
if ! qvm-run -p "$resources_vm" "cd '$resources_dir/media-creation/isos' && if ! [ -f '$iso' ]; then exit 1; fi"; then
    echo -e "${RED}[!]${NC} File not found in $resources_vm:$resources_dir/media-creation/isos: $iso" >&2
    exit 1
fi

# Validate answer-file
if ! qvm-run -p "$resources_vm" "cd '$resources_dir/media-creation/answer-files' && if ! [ -f '$answer_file' ]; then exit 1; fi"; then
    echo -e "${RED}[!]${NC} File not found in $resources_vm:$resources_dir/media-creation/answer-files: $answer_file" >&2
    exit 1
fi

# Install dependencies
echo -e "${BLUE}[i]${NC} Installing package dependencies on $resources_vm..." >&2
until qvm-run -p "$resources_vm" "cd '$resources_dir' && './install-dependencies.sh'" &> /dev/null; do
    echo -e "${RED}[!]${NC} Failed to install dependencies! Retrying in 10 seconds..." >&2
    sleep 10
done

# Put answer file into Windows media
autounattend_iso="${iso%.*}-autounattend.iso"
if ! qvm-run -p "$resources_vm" "cd '$resources_dir/media-creation' && if ! [ -f $autounattend_iso ]; then './create-media.sh' 'isos/$iso' 'answer-files/$answer_file'; fi"; then
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
    qvm-prefs "$current_name" maxmem 0 # Disables currently unstable Qubes memory manager (Also grays the option out in Qubes Manager)
    qvm-prefs "$current_name" kernel ''
    qvm-prefs "$current_name" qrexec_timeout 300 # Windows startup can take longer, especially if a disk scan is performed
    qvm-features "$current_name" video-model cirrus
    qvm-volume extend "$current_name":root 30g
    qvm-prefs "$current_name" netvm ""
    
    if [ "$background" == "true" ]; then
	while true; do
            if ! is_window_minimized "$current_name"; then
                minimize_window "$current_name"
            fi
            sleep 1
        done &
    fi

    echo -e "${BLUE}[i]${NC} Commencing first part of Windows installation process..." >&2
    until qvm-start --cdrom "$resources_vm:$resources_dir/media-creation/$autounattend_iso" "$current_name"; do
        echo -e "${RED}[!]${NC} Failed to start $current_name! Retrying in 10 seconds..." >&2
        sleep 10
    done

    # Waiting for first part of Windows installation process to finish...
    wait_for_shutdown "$current_name" "true"

    echo -e "${BLUE}[i]${NC} Commencing second part of Windows installation process..." >&2
    qvm-features --unset "$current_name" video-model
    until qvm-start "$current_name"; do
        echo -e "${RED}[!]${NC} Failed to start $current_name! Retrying in 10 seconds..." >&2
        sleep 10
    done

    # Waiting for second part of Windows installation process to finish...
    wait_for_shutdown "$current_name" "true"

    echo -e "${BLUE}[i]${NC} Setting up Auto Tools..." >&2
    # Configure automatic updates
    qvm-run -p "$resources_vm" "cd '$resources_dir/auto-tools/auto-tools/updates' && rm disable-updates" &> /dev/null
    if [ "$disable_updates" == "true" ]; then
        qvm-run -p "$resources_vm" "cd '$resources_dir/auto-tools/auto-tools/updates' && touch disable-updates"
    fi

    # Pack latest QWT into Auto Tools
    qvm-run -p "$resources_vm" "cat > '$resources_dir/qubes-windows-tools/qubes-windows-tools.iso'" < "/usr/lib/qubes/qubes-windows-tools.iso"
    qvm-run -p "$resources_vm" "cd '$resources_dir/qubes-windows-tools' && './unpack-qwt-iso.sh'" &> /dev/null

    # Create Auto Tools Media
    qvm-run -p "$resources_vm" "cd '$resources_dir/auto-tools' && './create-media.sh'" &> /dev/null

    echo -e "${BLUE}[i]${NC} Starting Windows with Auto Tools..." >&2
    qvm-prefs "$current_name" memory 1536
    # If packages are being downloaded than we must enable network access earlier
    if [ "$packages" != "" ]; then
        qvm-prefs "$current_name" netvm "$netvm"
    fi
    until qvm-start --cdrom "$resources_vm:$resources_dir/auto-tools/auto-tools.iso" "$current_name"; do
        echo -e "${RED}[!]${NC} Failed to start $current_name! Retrying in 10 seconds..." >&2
        sleep 10
    done

    # Waiting for updates to install...
    wait_for_shutdown "$current_name" "true"

    echo -e "${BLUE}[i]${NC} Installing Qubes Windows Tools..." >&2
    until qvm-start --cdrom "$resources_vm:$resources_dir/auto-tools/auto-tools.iso" "$current_name"; do
        echo -e "${RED}[!]${NC} $current_name failed to start! Retrying in 10 seconds..." >&2
        sleep 10
    done

    # Waiting for Qubes Windows Tools to shutdown computer automatically after install...
    wait_for_shutdown "$current_name" "true"

    echo -e "${BLUE}[i]${NC} Completing setup of Qubes Windows Tools..." >&2
    # If a NetVM is used then it must be set now because if done later then on the next boot a message will be received from Xen saying that the "Xen PV Network Class" driver hasn't been setup yet and a restart is required to do so (Also in Device Manager there will be error messages about the network driver). The NetVM cannot be set on the previous boot where QWT installation takes place because Windows suddenly shuts down during the "Configuring Windows updates" screen at boot
    # qvm-run doesn't work on this boot unless a NetVM is set. Upon next reboot vchan will work either way meaning qvm-run will work (More research required, may have changed)
    if [ "$netvm" ]; then
        qvm-prefs "$current_name" netvm "$netvm"
    fi
    # For an unknown reason, if the window is minimized at the "Welcome" logon screen (where QWT first enlarges Windows to fit the entire screen) the whole system will freeze until forcefully rebooted
    if [ "$background" == "true" ]; then
        kill "$!"
	wait "$!" 2> /dev/null
    fi
    qvm-start "$current_name"

    # Time must be given for the QWT drivers to complete setup
    # If packages are being installed then the time in which that is happening should be more than enough
    if [ "$packages" == "" ]; then
        sleep 180
    else
        echo -e "${BLUE}[i]${NC} Installing Chocolatey and packages..." >&2
        # Upon initial install of the Windows qube, qvm-run fails to run the command because it appears to try too early while Xen is still setting up drivers
        # To fix this, we wait until qvm-run successfully runs one time at which point we know the Windows qube is ready to accept further commands
        until qvm-run "$current_name" "echo Ready to accept commands?" &> /dev/null; do
            sleep 1
        done
        # Install Chocolatey (Command provided by: https://chocolatey.org/install)
        # Just added environment variable to use Windows compression so 7-Zip is not a mandatory install
        # shellcheck disable=SC2016
        qvm-run -p "$current_name" '@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "$env:chocolateyUseWindowsCompression = '\''true'\''; iex ((New-Object System.Net.WebClient).DownloadString('\''https://chocolatey.org/install.ps1'\''))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"' &> /dev/null
	# Install packages
        qvm-run -p "$current_name" "choco install -y ${packages//,/ }"
    fi

    # Shutdown and wait until complete before finishing or starting next installation
    qvm-shutdown "$current_name"
    wait_for_shutdown "$current_name" "false"
done

echo -e "${GREEN}[+]${NC} Completed successfully!"
