#!/bin/bash

[[ "$DEBUG" == 1 ]] && set -x

resources_dir="$(readlink -f "$(dirname "$0")")"
resources_qube="windows-mgmt"

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo_info() {
    echo -e "${BLUE}[i]${NC} $*" >&2
}

echo_ok() {
    echo -e "${GREEN}[i]${NC} $*" >&2
}

echo_err() {
    echo -e "${RED}[i]${NC} $*" >&2
}

error() {
    exit_code="$?"
    echo_err "An unexpected error has occurred! Exiting..."
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
    echo "Usage: $0 [options] <name>"
    echo "  -h, --help"
    echo "  -t, --template Make this qube a TemplateVM instead of a StandaloneVM"
    echo "  -n, --netvm <qube> NetVM for Windows to use"
    echo "  -s, --seamless Enable seamless mode persistently across reboots"
    echo "  -o, --optimize Optimize Windows by disabling unnecessary functionality for a qube"
    echo "  -y, --spyless Configure Windows telemetry settings to respect privacy"
    echo "  -w, --whonix Apply Whonix recommended settings for a Windows-Whonix-Workstation"
    echo "  -p, --packages <packages> Comma-separated list of packages to pre-install (see available packages at: https://chocolatey.org/packages)"
    echo "  -i, --iso <file> Windows media to automatically install and setup (default: $iso)"
    echo "  -a, --answer-file <xml file> Settings for Windows installation (default: $answer_file)"
    echo ""
    echo "Available ISOs:"
    find "$resources_dir/windows-media/isos" -type f -name '*.iso' -printf '  %P\n'
    echo ""
    echo "Available answer files:"
    find "$resources_dir/windows-media/answer-files" -type f -name '*.xml' -printf '  %P\n'
}

# Option strings
short="h:tn:soywp:i:a:"
long="help:,template,netvm:,seamless,optimize,spyless,whonix,packages:,iso:,answer-file:"

# Read options
if ! opts=$(getopt --options=$short --longoptions=$long --name "$0" -- "$@"); then
    exit 1
fi
eval set -- "$opts"

# Set defaults
iso="win7x64-ultimate.iso"
answer_file="win7x64-ultimate.xml"

# Put options into variables
while true; do
    case "$1" in
        -h | --help)
            usage
            exit
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

# Validate name
if qvm-check "$name" &> /dev/null; then
    echo_err "Qube already exists: $name"
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
        echo_err "NetVM does not exist: $netvm"
        exit 1
    elif [ "$(qvm-prefs "$netvm" provides_network)" != "True" ]; then
        echo_err "Not a NetVM: $netvm"
        exit 1
    fi
fi

# Validate packages
if [ "$packages" ]; then
    if ! [ "$netvm" ]; then
        echo_err "A NetVM must be configured to use packages"
        exit 1
    fi

    if qvm-tags "$netvm" list anon-gateway &> /dev/null; then
        echo_err "Due to Chocolatey blocking Tor, packages cannot be used with NetVM: $netvm"
        exit 1
    fi

    # If resources qube has a NetVM (is not air gapped) that is not an anon-gateway (Tor is blocked) then check if packages exist
    resources_netvm="$(qvm-prefs "$resources_qube" netvm)"
    if [ "$resources_netvm" ] && ! qvm-tags "$resources_netvm" list anon-gateway &> /dev/null; then
        IFS="," read -ra package_arr <<< "$packages"
        for package in "${package_arr[@]}"; do
            if [ "$(curl -so /dev/null -w '%{http_code}' "https://chocolatey.org/api/v2/package/$package")" != 404 ]; then
                echo_err "Package not found: $package"
                exit 1
            fi
        done
    fi
fi

# Validate iso
if ! [ -f "$resources_dir/windows-media/isos/$iso" ]; then
    echo_err "File not found in $resources_dir/windows-media/isos: $iso"
    exit 10
fi

# Validate answer-file
if ! [ -f "$resources_dir/windows-media/answer-files/$answer_file" ]; then
    echo_err "File not found in $resources_dir/windows-media/answer-files: $answer_file"
    exit 10
fi

# Put answer file into Windows media
echo_info "Preparing Windows media for automatic installation..."
if [ -f "$resources_dir/windows-media/isos/$iso" ]; then
    cd "$resources_dir/windows-media" || exit 1
    ./create-media.sh "isos/$iso" "answer-files/$answer_file"
else
    echo_err "Failed to create media! Out of disk space? Exiting..."
    exit 1
fi

# Create Windows qube the number of times specified using name as the basename if creating more than 1
qube="$name"

echo_info "Starting creation of $qube"
qvm-create --class "$class" --label red "$qube"
qvm-prefs "$qube" virt_mode hvm
qvm-prefs "$qube" memory 1024
qvm-prefs "$qube" maxmem 0 # Disable currently unstable Qubes memory manager (Also gray the option out in qubes-vm-settings)
qvm-prefs "$qube" kernel ""
qvm-prefs "$qube" qrexec_timeout 300 # Windows startup can take longer, especially if a disk scan is performed
qvm-features "$qube" video-model cirrus
qvm-volume extend "$qube:root" 30GiB
qvm-prefs "$qube" netvm ""

echo_info "Starting first part of Windows installation process..."

# Existing block device identifier is needed when running from outside of dom0
# We create a loop device exposing the iso
DEV_LOOP="$(sudo losetup --show -f -P "$resources_dir/windows-media/out/$iso" 2>/dev/null)"
if [[ $DEV_LOOP =~ /dev/loop[0-9]+ ]]; then
    if ! qvm-start --cdrom "$resources_qube:${DEV_LOOP//\/dev\//}" "$qube"; then
        echo_err "Failed to start $qube! Retrying in 10 seconds..."
        exit 1
    fi
else
    echo_err "Failed to create loop device for $iso. Exiting..."
    exit 1
fi

# Waiting for first part of Windows installation process to finish...
wait_for_shutdown

echo_info "Starting second part of Windows installation process..."
qvm-features --unset "$qube" video-model
if ! qvm-start "$qube"; then
    echo_err "Failed to start $qube! Retrying in 10 seconds..."
    exit 1
fi

# Waiting for second part of Windows installation process to finish...
wait_for_shutdown

if [ -f /usr/lib/qubes/qubes-windows-tools.iso ]; then
    echo_info "Preparing Qubes Windows Tools for automatic installation..."
    # Unpack latest QWT into auto-qwt
    ln -sf /usr/lib/qubes/qubes-windows-tools.iso "$resources_dir/tools-media/qwt-installer.iso"
    cd "$resources_dir/tools-media" && ./unpack-qwt-installer-media.sh

    # Create auto-qwt media
    cd "$resources_dir/tools-media" && "./pack-auto-qwt.sh"

    echo_info "Installing Qubes Windows Tools..."

    # NetVM must be attached for Xen PV network driver setup
    # However, to keep Windows air gapped for the entire setup we drop all packets at the firewall so Windows cannot connect to the Internet yet
    if [ "$netvm" ]; then
        qvm-firewall "$qube" del accept
        qvm-firewall "$qube" add drop
        qvm-prefs "$qube" netvm "$netvm"
    fi

    DEV_LOOP="$(sudo losetup --show -f -P "$resources_qube:$resources_dir/tools-media/auto-qwt.iso" 2>/dev/null)"
    if [[ $DEV_LOOP =~ /dev/loop[0-9]+ ]]; then
        if ! qvm-start --cdrom "$resources_qube:${DEV_LOOP//\/dev\//}" "$qube"; then
            echo_err "Failed to start $qube! Retrying in 10 seconds..."
            exit 1
        fi
    else
        echo_err "Failed to create loop device for auto-qwt.iso. Exiting..."
        exit 1
    fi

    # Waiting for automatic shutdown after Qubes Windows Tools install...
    wait_for_shutdown

    echo_info "Starting setup of Qubes Windows Tools..."
    if ! qvm-start "$qube"; then
        echo_err "Failed to start $qube! Retrying in 10 seconds..."
        exit 1
    fi

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

    # Copy post scripts from resources qube to Windows
    cd "$resources_dir" && qvm-copy-to-vm "$qube" post

    post_incoming_dir="%USERPROFILE%\\Documents\\QubesIncoming\\$resources_qube\\post"

    if [ "$seamless" == "true" ]; then
        echo_info "Enabling seamless mode persistently..."
        qvm-run -q "$qube" "cd $post_incoming_dir && seamless.bat" || true
    fi

    if [ "$optimize" == "true" ]; then
        echo_info "Optimizing Windows..."
        qvm-run -q "$qube" "cd $post_incoming_dir && optimize.bat" || true
    fi

    if [ "$spyless" == "true" ]; then
        echo_info "Disabling Windows telemetry..."
        qvm-run -q "$qube" "cd $post_incoming_dir && spyless.bat" || true
    fi

    if [ "$whonix" == "true" ]; then
        echo_info "Applying Whonix recommended settings for a Windows-Whonix-Workstation..."
        qvm-tags "$qube" add anon-vm
        qvm-run -q "$qube" "cd $post_incoming_dir && whonix.bat" || true
    fi

    # Let Windows connect to the Internet
    # After spyless and whonix scripts but before packages
    # Independent of whether or not packages are being installed, user-defined commands should have Internet access for consistency
    if [ "$netvm" ]; then
        echo_info "Breaking air gap so Windows can connect to the Internet..."
        qvm-firewall "$qube" del drop
        qvm-firewall "$qube" add accept
    fi

    if [ "$packages" ]; then
        echo_info "Installing packages..."
        qvm-run -p "$qube" "cd $post_incoming_dir && powershell -ExecutionPolicy Bypass -Command .\\packages.ps1 $packages <nul" || true

        # Add new apps to app menu
        qvm-sync-appmenus "$qube" &> /dev/null
    fi

    echo_info "Running user-defined custom commands..."
    qvm-run -p "$qube" "cd $post_incoming_dir && run.bat" || true

    # Clean up post scripts and remove policy
    qvm-run -q "$qube" "rmdir /s /q $post_incoming_dir\\..\\.." || true

    # Shutdown and wait until complete before finishing or starting next installation
    if qvm-run -q "$qube" "shutdown /s /t 0"; then
        # This is a more graceful method of shutdown
        wait_for_shutdown
    else
        echo_err "Qubes Windows Tools has stopped working! This is probably the result of installing a conflicting package. Shutting down..."
        # Example of conflicting package: vcredist140 (during install of vcredist140-x64)
        qvm-shutdown --wait "$qube"
    fi
else
    echo_info "Qubes Windows Tools ISO not found. Ignoring..."
fi

# Give reasonable amount of memory for actual use
qvm-prefs "$qube" memory 2048

# Remove previously created loop devices
sudo losetup -D

echo_ok "Completed successfully!"
