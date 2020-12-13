#!/bin/bash

# Answer file templates: https://github.com/boxcutter/windows/tree/master/floppy

# Optional: Validate answer file with Windows AIK/ADK (Must add cpi:offlineImage tag to answer file referencing the CLG or WIM file embedded in the ISO)

# Get product key: https://github.com/mrpeardotnet/WinProdKeyFinder/releases
# Install desired edition (Home, Ultimate, Pro, etc.) of any given Windows media manually then proceed to run WinProdKeyFinder to get the trial key and use it in the answer file
# Specifying a key is not required for "Evaluation" Windows media

# Update: Found a way to avoid hardcoding the product key for any version/edition of Windows which is great because it makes the answer files more adaptable to working with any given Windows media
# Also, we don't have to do the tedious work of installing the Windows media manually then running that tool to get the trial product key

[[ "$DEBUG" == 1 ]] && set -x
localdir="$(readlink -f "$(dirname "$0")")"
scriptsdir="$(readlink -f "$localdir/../scripts")"

# shellcheck source=scripts/common.sh
source "$scriptsdir/common.sh"
# shellcheck source=scripts/clean-timestamps.sh
source "$scriptsdir/clean-timestamps.sh"

usage() {
    echo "Usage: $0 iso answer_file"
}

exit_clean() {
    local exit_code="$?"

    if [ -n "$iso_loop" ]; then
        echo_info "Unmounting loop device for $iso..."
        if [ -n "$iso_mntpoint" ]; then
            sudo umount "$iso_mntpoint"
        fi

        echo_info "Deleting loop device..."
        sudo losetup -d "/dev/$iso_loop"
    fi

    if [ -d "$temp_dir" ]; then
        echo_info "Deleting temporary folder..."
        chmod -R +w "$temp_dir" # Read-only permissions were inherited because ISO 9660 is a read-only filesystem
        rm -r "$temp_dir"
    fi

    if [ "$exit_code" != 0 ]; then
        if [ -f "$final_iso" ]; then
            echo_info "Deleting incomplete ISO output..."
            rm "$final_iso"
        fi
        echo_err "Failed to create automatic Windows installation media!"
    else
        echo_ok "Created automatic Windows installation media for $(basename "$final_iso") successfully!"
    fi
    exit "$exit_code"
}

for arg in "$@"; do
    if [ "$arg" == "-h" ] || [ "$arg" == "--help" ]; then
        usage
        exit
    fi
done

if [ "$#" != "2" ]; then
    usage
    exit 1
fi

iso="$1"
answer_file="$2"

if ! [ -f "$iso" ]; then
    echo_err "ISO file not found: $iso"
    exit 1
fi

if ! [ -f "$answer_file" ]; then
    echo_err "Answer file not found: $answer_file"
    exit 1
fi

trap exit_clean EXIT ERR INT

echo_info "Creating loop device from ISO..."
iso_loop="$(mount_loop "$iso")"

if [ -z "$iso_loop" ]; then
    echo_err "Failed to create loop device for $iso. Exiting..."
    exit 1
fi

echo_info "Mounting loop device..."
iso_mntpoint="$(mktemp -d)"
if ! sudo mount "/dev/$iso_loop" "$iso_mntpoint" >/dev/null 2>&1; then
    echo_err "Failed to mount loop device for $iso. Exiting..."
    exit 1
fi

echo_info "Copying loop device contents to temporary folder..."
temp_dir="$(mktemp --directory --tmpdir=out)" # The default /tmp may be too small
cp -r "$iso_mntpoint/." "$temp_dir"

echo_info "Copying answer file to Autounattend.xml in temporary folder..."
cp "$answer_file" "$temp_dir/Autounattend.xml"

echo_info "Creating new ISO..."
# https://rwmj.wordpress.com/2010/11/04/customizing-a-windows-7-install-iso
# https://theunderbase.blogspot.com/2013/03/editing-bootable-dvds-as-iso-images.html

# Get boot image
geteltorito -o "$temp_dir/boot.bin" "$iso"

clean_file_timestamps_recursively "$temp_dir"

final_iso="${iso/isos/out}"
# -allow-limited-size allows for larger files such as the install.wim which is the Windows image
run_clean_time_command genisoimage -udf -b boot.bin -no-emul-boot -allow-limited-size -quiet -o "$final_iso" "$temp_dir"

clean_file_timestamp "$final_iso"
