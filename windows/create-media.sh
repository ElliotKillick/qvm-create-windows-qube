#!/bin/bash

# Copyright (C) 2023 Elliot Killick <contact@elliotkillick.com>
# Licensed under the MIT License. See LICENSE file for details.

# Answer file templates: https://github.com/boxcutter/windows/tree/master/floppy

# Optional: Validate answer file with Windows AIK/ADK (Must add cpi:offlineImage tag to answer file referencing the CLG or WIM file embedded in the ISO)

# Get product key: https://github.com/mrpeardotnet/WinProdKeyFinder/releases
# Install desired edition (Home, Ultimate, Pro, etc.) of any given Windows media manually then proceed to run WinProdKeyFinder to get the trial key and use it in the answer file
# Specifying a key is not required for "Evaluation" Windows media

# Update: Found a way to avoid hardcoding the product key for any version/edition of Windows which is great because it makes the answer files more adaptable to working with any given Windows media
# Also, we don't have to do the tedious work of installing the Windows media manually then running that tool to get the trial product key

# Test for 4-bit color (16 colors)
if [ "0$(tput colors 2> /dev/null)" -ge 16 ]; then
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    NC='\033[0m'
fi

# Avoid printing messages as potential terminal escape sequences
echo_ok() { printf "%b%s%b" "${GREEN}[+]${NC} " "$1" "\n" >&2; }
echo_info() { printf "%b%s%b" "${BLUE}[i]${NC} " "$1" "\n" >&2; }
echo_err() { printf "%b%s%b" "${RED}[!]${NC} " "$1" "\n" >&2; }

usage() {
    echo "Usage: $0 iso answer_file"
}

for arg in "$@"; do
    if [ "$arg" == "-h" ] || [ "$arg" == "--help" ]; then
        usage
        exit
    fi
done

if [ "$#" != "2" ]; then
    usage >&2
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

clean_exit() {
    exit_code="$?"

    if [ "$iso_device" ]; then
        if findmnt "$iso_device" > /dev/null; then
            echo_info "Unmounting loop device..."
            udisksctl unmount --block-device "$iso_device"
        fi

        echo_info "Deleting loop device..."
        udisksctl loop-delete --block-device "$iso_device"
    fi

    if [ -f "$boot_img" ]; then
        echo_info "Deleting temporary boot image..."
        rm -f "$boot_img"
    fi

    if [ "$exit_code" != 0 ]; then
        if [ -f "$out_iso" ]; then
            echo_info "Deleting partial ISO output..."
            rm "$out_iso"
        fi

        echo_err "Failed to create automatic Windows installation media!"
        exit "$exit_code"
    fi

    echo_ok "Created automatic Windows installation media for $(basename "$out_iso") successfully!"
}

trap clean_exit EXIT
trap exit ERR INT

# shellcheck source=clean-timestamps.sh
source clean-timestamps.sh

echo_info "Creating loop device from ISO..."
iso_device="$(udisksctl loop-setup --file "$iso")"
iso_device="${iso_device#Mapped file * as }"
iso_device="${iso_device%.}"

echo_info "Mounting loop device..."
# Fix race condition where disk tries to mount before finishing setup
until iso_mntpoint="$(udisksctl mount --block-device "$iso_device")"; do
    sleep 1
done
iso_mntpoint="${iso_mntpoint#Mounted * at }"
iso_mntpoint="${iso_mntpoint%.}"

echo_info "Creating new ISO..."
# https://rwmj.wordpress.com/2010/11/04/customizing-a-windows-7-install-iso
# https://theunderbase.blogspot.com/2013/03/editing-bootable-dvds-as-iso-images.html

local_dir="$(dirname "$(readlink -f -- "$0")")"

# Get boot image
boot_img="$(mktemp --tmpdir boot.bin.XXXXX )"
PATH="$PATH:$local_dir" geteltorito -o "$boot_img" "$iso"

out_iso="${iso/isos/out}"
# -allow-limited-size allows for larger files such as install.wim which is the Windows image
run_clean_time_command \
    genisoimage -udf -b boot.bin -no-emul-boot -allow-limited-size -quiet -graft-points -o "$out_iso" \
    "$iso_mntpoint" "boot.bin=$boot_img" "Autounattend.xml=$answer_file"

clean_file_timestamp "$out_iso"
