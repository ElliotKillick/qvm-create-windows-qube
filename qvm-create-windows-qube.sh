#!/bin/bash

set -e
[[ "$DEBUG" == 1 ]] && set -x

resources_dir="$(readlink -f "$(dirname "$0")")"
resources_qube="windows-mgmt"

# shellcheck source=./scripts/common.sh
source "$resources_dir/scripts/common.sh"

exit_clean() {
    local exit_code="$?"

    # Remove previously created loop devices
    sudo losetup -D

    if [ $exit_code -eq 0 ]; then
        echo_ok "Completed successfully!"
    elif [ $exit_code -ne 10 ]; then
        echo_err "An error has occurred! Exiting..."
    fi
    exit "$exit_code"
}

wait_for_shutdown() {
    # There is a small delay upon booting a qube before qvm-check will detect it as running
    # To account for this as well as scenarios where the qube is already running and is shutting down we need both loops
    until qvm-check --running "$qube" &> /dev/null; do
        sleep 3
    done
    while qvm-check --running "$qube" &> /dev/null; do
        sleep 3
    done
}

usage() {
    echo "Usage: $0 [options] <name>"
    echo "  -h, --help"
    echo "  -t, --template Make this qube a TemplateVM instead of a StandaloneVM"
    echo "  -n, --netvm <qube> NetVM for Windows to use"
    echo "  -w, --with-internet Allow network traffic to internet at first boot only"
    echo "  -i, --iso <file> Windows media to automatically install and setup (default: $iso)"
    echo "  -a, --answer-file <xml file> Settings for Windows installation (default: $answer_file)"
    echo "  -p, --post-iso <file> Media containing 'run.bat' to run at firstboot"
    echo ""
    echo "Available ISOs:"
    find "$resources_dir/windows-media/isos" -type f -name '*.iso' -printf '  %P\n'
    echo ""
    echo "Available answer files:"
    find "$resources_dir/windows-media/answer-files" -type f -name '*.xml' -printf '  %P\n'
}

# Option strings
short="h:tn:w,i:a:p:"
long="help:,template,netvm:,with-internet,iso:,answer-file:,post-iso:"

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
        -w | --with-internet)
            with_internet="true"
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
        -p | --post-iso)
            # No restriction on post-iso location
            post_iso="$(readlink -f "$2")"
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

trap exit_clean 0 1 2 3 6 15

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

# Validate iso
if ! [ -f "$resources_dir/windows-media/isos/$iso" ]; then
    echo_err "File not found in $resources_dir/windows-media/isos: $iso"
    exit 1
fi

# Validate answer-file
if ! [ -f "$resources_dir/windows-media/answer-files/$answer_file" ]; then
    echo_err "File not found in $resources_dir/windows-media/answer-files: $answer_file"
    exit 1
fi

# Validate post-iso
if [ -n "$post_iso" ] && [ ! -f "$post_iso" ]; then
    echo_err "File not found: $post_iso"
    exit 1
fi

# Put answer file into Windows media
echo_info "Preparing Windows media for automatic installation..."
if [ -f "$resources_dir/windows-media/isos/$iso" ]; then
    cd "$resources_dir/windows-media"
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
qvm-prefs "$qube" memory 2048
qvm-prefs "$qube" maxmem 0 # Disable currently unstable Qubes memory manager (Also gray the option out in qubes-vm-settings)
qvm-prefs "$qube" kernel ""
qvm-prefs "$qube" qrexec_timeout 300 # Windows startup can take longer, especially if a disk scan is performed
qvm-features "$qube" video-model cirrus
qvm-volume extend "$qube:root" 30GiB
qvm-prefs "$qube" netvm ""

echo_info "Starting first part of Windows installation process..."

# Existing block device identifier is needed when running from outside of dom0
# We create a loop device exposing the iso
windows_iso_loop="$(mount_loop "$resources_dir/windows-media/out/$iso")"
if [ -n "${windows_iso_loop}" ]; then
    if ! qvm-start --cdrom "$resources_qube:${windows_iso_loop}" "$qube"; then
        echo_err "Failed to start $qube!"
        exit 1
    fi
else
    echo_err "Failed to create loop device for $iso. Exiting..."
    exit 1
fi

# Waiting for first part of Windows installation process to finish...
wait_for_shutdown

# Free loopdev for windows_iso
sudo losetup -d "/dev/${windows_iso_loop}"

echo_info "Starting second part of Windows installation process..."
qvm-features --unset "$qube" video-model
if ! qvm-start "$qube"; then
    echo_err "Failed to start $qube!"
    exit 1
fi

# Waiting for second part of Windows installation process to finish...
wait_for_shutdown

if [ -n "$post_iso" ]; then
    echo_info "Starting third part of Windows installation process (custom firstboot)..."

    if [ "$netvm" ]; then
        if [ "${with_internet}" == "true" ]; then
            qvm-firewall "$qube" del drop
            qvm-firewall "$qube" add accept
        else
            qvm-firewall "$qube" del accept
            qvm-firewall "$qube" add drop
        fi

        qvm-prefs "$qube" netvm "$netvm"
    fi

    post_iso_loop="$(mount_loop "$post_iso")"
    if [ -n "${post_iso_loop}" ]; then
        if ! qvm-start --cdrom "$resources_qube:${post_iso_loop}" "$qube"; then
            echo_err "Failed to start $qube!"
            exit 1
        fi
    else
        echo_err "Failed to create loop device for post-install iso. Exiting..."
        exit 1
    fi

    # Waiting for third part of Windows installation process to finish...
    wait_for_shutdown

    # Free loopdev for post_iso
    sudo losetup -d "/dev/${post_iso_loop}"
fi
