#!/bin/bash

# Copyright (C) 2019 Elliot Killick <elliotkillick@zohomail.eu>
# Licensed under the MIT License. See LICENSE file for details.

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

error() {
    exit_code="$?"
    echo -e "${RED}[!]${NC} An unexpected error has occurred! Exiting..." >&2
    exit "$exit_code"
}

trap error ERR

wait_for_shutdown() {
    # There is a small delay upon booting a qube before qvm-check will detect it as running
    # To account for this as well as scenarios where the qube is already running and is shutting down we need both loops
    until qvm-check --running "$qube" &> /dev/null; do
        sleep 1
    done
    while qvm-check --running "$qube" &> /dev/null; do
        sleep 1
    done
}

usage() {
    echo "Usage: $0 [options] -i <iso> -a <answer file> <name>"
    echo "  -h, --help"
    echo "  -c, --count <number> Number of Windows qubes with given basename desired"
    echo "  -t, --template Make this qube a TemplateVM instead of a StandaloneVM"
    echo "  -n, --netvm <qube> NetVM for Windows to use"
    echo "  -s, --seamless Enable seamless mode persistently across reboots"
    echo "  -o, --optimize Optimize Windows by disabling unnecessary functionality for a qube"
    echo "  -y, --spyless Configure Windows telemetry settings to respect privacy"
    echo "  -w, --whonix Apply Whonix recommended settings for a Windows-Whonix-Workstation"
    echo "  -p, --packages <packages> Comma-separated list of packages to pre-install (see available packages at: https://chocolatey.org/packages)"
    echo "  -i, --iso <file> Windows media to automatically install and setup"
    echo "  -a, --answer-file <xml file> Settings for Windows installation"
}

# Option strings
short="hc:tn:soywp:i:a:"
long="help,count:,template,netvm:,seamless,optimize,spyless,whonix,packages:,iso:,answer-file:"

# Read options
if ! opts=$(getopt --options=$short --longoptions=$long --name "$0" -- "$@"); then
    exit 1
fi
eval set -- "$opts"

# Set defaults
count="1"

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
        -t | --template)
            template="true"
            shift
            ;;
        -n | --netvm)
            netvm="$2"
            shift 2
            ;;
        -s | --seamless)
            seamless="true"
            shift
            ;;
        -o | --optimize)
            optimize="true"
            shift
            ;;
        -y | --spyless)
            spyless="true"
            shift
            ;;
        -w | --whonix)
            whonix="true"
            shift
            ;;
        -p | --packages)
            packages="$2"
            shift 2
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

# Validate this is Dom0
#if [ "$(hostname)" != "dom0" ]; then
#    echo -e "${RED}[!]${NC} This script must be run in Dom0" >&2
#    exit 1
#fi

# Validate name
if [ "$count" == 1 ]; then
    if qvm-check "$name" &> /dev/null; then
        echo -e "${RED}[!]${NC} Qube already exists: $name" >&2
        exit 1
    fi
fi

# Validate count
if ! [[ "$count" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}[!]${NC} Count is not a number" >&2
    exit 1
elif [ "$count" -lt 1 ]; then
    echo -e "${RED}[!]${NC} Count should be 1 or more" >&2
    exit 1
fi

# Parse template
if [ "$template" == "true" ]; then
    class="TemplateVM"
else
    class="StandaloneVM"
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

# Validate packages
if [ "$packages" ]; then
    if ! [ "$netvm" ]; then
        echo -e "${RED}[!]${NC} A NetVM must be configured to use packages" >&2
        exit 1
    fi

    if qvm-tags "$netvm" list anon-gateway &> /dev/null; then
        echo -e "${RED}[!]${NC} Due to Chocolatey blocking Tor, packages cannot be used with NetVM: $netvm" >&2
        exit 1
    fi

    # If resources qube has a NetVM (is not air gapped) that is not an anon-gateway (Tor is blocked) then check if packages exist
    resources_netvm="$(qvm-prefs "$resources_qube" netvm)"
    if [ "$resources_netvm" ] && ! qvm-tags "$resources_netvm" list anon-gateway &> /dev/null; then
        IFS="," read -ra package_arr <<< "$packages"
        for package in "${package_arr[@]}"; do
            if qvm-run -q "$resources_qube" "if [ \"\$(curl -so /dev/null -w '%{http_code}' 'https://chocolatey.org/api/v2/package/$package')\" != 404 ]; then exit 1; fi"; then
                echo -e "${RED}[!]${NC} Package not found: $package" >&2
                exit 1
            fi
        done
    fi
fi

no_iso_error() {
    echo -e "${BLUE}[i]${NC} Available ISOs:" >&2
    qvm-run -p "$resources_qube" "cd '$resources_dir/windows-media/isos' && find -type f -name '*.iso' -printf '%P\n'"
    exit 1
}

# Validate iso
if ! [ "$iso" ]; then
    echo -e "${RED}[!]${NC} ISO not specified"
    no_iso_error
elif ! qvm-run -q "$resources_qube" "cd '$resources_dir/windows-media/isos' && if ! [ -f '$iso' ]; then exit 1; fi"; then
    echo -e "${RED}[!]${NC} File not found in $resources_qube:$resources_dir/windows-media/isos: $iso" >&2
    no_iso_error
fi

no_answer_file_error() {
    echo -e "${BLUE}[i]${NC} Available answer files:" >&2
    qvm-run -p "$resources_qube" "cd '$resources_dir/windows-media/answer-files' && find -type f -name '*.xml' -printf '%P\n'"
    exit 1
}

# Validate answer-file
if ! [ "$answer_file" ]; then
    echo -e "${RED}[!]${NC} Answer file not specified"
    no_answer_file_error
elif ! qvm-run -q "$resources_qube" "cd '$resources_dir/windows-media/answer-files' && if ! [ -f '$answer_file' ]; then exit 1; fi"; then
    echo -e "${RED}[!]${NC} File not found in $resources_qube:$resources_dir/windows-media/answer-files: $answer_file" >&2
    no_answer_file_error
fi

# Put answer file into Windows media
echo -e "${BLUE}[i]${NC} Preparing Windows media for automatic installation..." >&2
if ! qvm-run -p "$resources_qube" "cd '$resources_dir/windows-media' && if ! [ -f out/$iso ]; then './create-media.sh' 'isos/$iso' 'answer-files/$answer_file'; fi"; then
    echo -e "${RED}[!]${NC} Failed to create media! Out of disk space? Exiting..." >&2
    exit 1
fi

# Create Windows qube the number of times specified using name as the basename if creating more than 1
for (( counter = 1; counter <= count; counter++ )); do
    if [ "$count" -gt 1 ]; then
        qube="$name-$counter"

        # If qube with that name already exists, keep incrementing the number until one that does not exist is found
        i=0
        while qvm-check "$qube" &> /dev/null; do
            ((i++)) || true
            qube="$name-$i"
        done
    else
        qube="$name"
    fi

    echo -e "${BLUE}[i]${NC} Starting creation of $qube" >&2
    qvm-create --class "$class" --label red "$qube"
    qvm-prefs "$qube" virt_mode hvm
    qvm-prefs "$qube" memory 1024
    qvm-prefs "$qube" maxmem 0 # Disable currently unstable Qubes memory manager (Also gray the option out in qubes-vm-settings)
    qvm-prefs "$qube" kernel ""
    qvm-prefs "$qube" qrexec_timeout 300 # Windows startup can take longer, especially if a disk scan is performed
    qvm-features "$qube" video-model cirrus
    qvm-volume extend "$qube:root" 30GiB
    qvm-prefs "$qube" netvm ""

    echo -e "${BLUE}[i]${NC} Commencing first part of Windows installation process..." >&2
    until qvm-start --cdrom "$resources_qube:$resources_dir/windows-media/out/$iso" "$qube"; do
        echo -e "${RED}[!]${NC} Failed to start $qube! Retrying in 10 seconds..." >&2
        sleep 10
    done

    # Waiting for first part of Windows installation process to finish...
    wait_for_shutdown

    echo -e "${BLUE}[i]${NC} Commencing second part of Windows installation process..." >&2
    qvm-features --unset "$qube" video-model
    until qvm-start "$qube"; do
        echo -e "${RED}[!]${NC} Failed to start $qube! Retrying in 10 seconds..." >&2
        sleep 10
    done

    # Waiting for second part of Windows installation process to finish...
    wait_for_shutdown

    echo -e "${BLUE}[i]${NC} Preparing Qubes Windows Tools for automatic installation..." >&2
    # Unpack latest QWT into auto-qwt
    qvm-run -p "$resources_qube" "cat > '$resources_dir/tools-media/qwt-installer.iso'" < "/usr/lib/qubes/qubes-windows-tools.iso"
    qvm-run -q "$resources_qube" "cd '$resources_dir/tools-media' && './unpack-qwt-installer-media.sh'"

    # Create auto-qwt media
    qvm-run -q "$resources_qube" "cd '$resources_dir/tools-media' && './pack-auto-qwt.sh'"

    echo -e "${BLUE}[i]${NC} Installing Qubes Windows Tools..." >&2

    # NetVM must be attached for Xen PV network driver setup
    # However, to keep Windows air gapped for the entire setup we drop all packets at the firewall so Windows cannot connect to the Internet yet
    if [ "$netvm" ]; then
        qvm-firewall "$qube" del accept
        qvm-firewall "$qube" add drop
        qvm-prefs "$qube" netvm "$netvm"
    fi

    until qvm-start --cdrom "$resources_qube:$resources_dir/tools-media/auto-qwt.iso" "$qube"; do
        echo -e "${RED}[!]${NC} Failed to start $qube! Retrying in 10 seconds..." >&2
        sleep 10
    done

    # Waiting for automatic shutdown after Qubes Windows Tools install...
    wait_for_shutdown

    echo -e "${BLUE}[i]${NC} Completing setup of Qubes Windows Tools..." >&2
    until qvm-start "$qube"; do
        echo -e "${RED}[!]${NC} Failed to start $qube! Retrying in 10 seconds..." >&2
        sleep 10
    done

    # Wait until QWT installation is advertised to Dom0
    until [ "$(qvm-features "$qube" os)" == "Windows" ]; do
        sleep 1
    done

    # At this point, qvm-run is working

    # Wait for app menu to synchronize (Automatically done once Qubes detects QWT)
    command_pattern="/usr/bin/python3 /usr/bin/qvm-sync-appmenus $qube"
    # Sync usually starts right away but due to a race condition we need both loops to make sure we catch when the sync begins and wait until it ends
    until pgrep -fx "$command_pattern" &> /dev/null; do
        sleep 1
    done
    while pgrep -fx "$command_pattern" &> /dev/null; do
        sleep 1
    done

    # Post QWT scripts

    # Prepend allowing policy to qubes.Filecopy and copy post scripts from resources qube to Windows
    policy="$resources_qube $qube allow"
    policy_file="/etc/qubes-rpc/policy/qubes.Filecopy"
    sed -i "1i$policy" "$policy_file"
    qvm-run -q "$resources_qube" "cd '$resources_dir' && qvm-copy-to-vm $qube post"

    post_incoming_dir="%USERPROFILE%\\Documents\\QubesIncoming\\$resources_qube\\post"

    if [ "$seamless" == "true" ]; then
        echo -e "${BLUE}[i]${NC} Enabling seamless mode persistently..." >&2
        qvm-run -q "$qube" "cd $post_incoming_dir && seamless.bat" || true
    fi

    if [ "$optimize" == "true" ]; then
        echo -e "${BLUE}[i]${NC} Optimizing Windows..." >&2
        qvm-run -q "$qube" "cd $post_incoming_dir && optimize.bat" || true
    fi

    if [ "$spyless" == "true" ]; then
        echo -e "${BLUE}[i]${NC} Disabling Windows telemetry..." >&2
        qvm-run -q "$qube" "cd $post_incoming_dir && spyless.bat" || true
    fi

    if [ "$whonix" == "true" ]; then
        echo -e "${BLUE}[i]${NC} Applying Whonix recommended settings for a Windows-Whonix-Workstation..." >&2
        qvm-tags "$qube" add anon-vm
        qvm-run -q "$qube" "cd $post_incoming_dir && whonix.bat" || true
    fi

    # Let Windows connect to the Internet
    # After spyless and whonix scripts but before packages
    # Independent of whether or not packages are being installed, user-defined commands should have Internet access for consistency
    if [ "$netvm" ]; then
        echo -e "${BLUE}[i]${NC} Breaking air gap so Windows can connect to the Internet..." >&2
        qvm-firewall "$qube" del drop
        qvm-firewall "$qube" add accept
    fi

    if [ "$packages" ]; then
        echo -e "${BLUE}[i]${NC} Installing packages..." >&2
        qvm-run -p "$qube" "cd $post_incoming_dir && powershell -ExecutionPolicy Bypass -Command .\\packages.ps1 $packages <nul" || true

        # Add new apps to app menu
        qvm-sync-appmenus "$qube" &> /dev/null
    fi

    echo -e "${BLUE}[i]${NC} Running user-defined custom commands..." >&2
    qvm-run -p "$qube" "cd $post_incoming_dir && run.bat" || true

    # Clean up post scripts and remove policy
    qvm-run -q "$qube" "rmdir /s /q $post_incoming_dir\\..\\.." || true
    sed -i "/^$policy$/d" "$policy_file"

    # Shutdown and wait until complete before finishing or starting next installation
    if qvm-run -q "$qube" "shutdown /s /t 0"; then
        # This is a more graceful method of shutdown
        wait_for_shutdown
    else
        echo -e "${RED}[!]${NC} Qubes Windows Tools has stopped working! This is probably the result of installing a conflicting package. Shutting down..." >&2
        # Example of conflicting package: vcredist140 (during install of vcredist140-x64)
        qvm-shutdown --wait "$qube"
    fi

    # Give reasonable amount of memory for actual use
    qvm-prefs "$qube" memory 2048

    if [ "$count" -gt 1 ]; then
        echo -e "${GREEN}[+]${NC} Finished creation of $qube successfully!"
    fi
done

echo -e "${GREEN}[+]${NC} Completed successfully!"
