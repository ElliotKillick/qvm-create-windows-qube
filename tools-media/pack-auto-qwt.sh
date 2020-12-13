#!/bin/bash

[[ "$DEBUG" == 1 ]] && set -x
localdir="$(readlink -f "$(dirname "$0")")"
scriptsdir="$(readlink -f "$localdir/../scripts")"

# shellcheck source=scripts/common.sh
source "$scriptsdir/common.sh"

echo_info "Preparing Qubes Windows Tools for automatic installation..."
if ! [ -f /usr/lib/qubes/qubes-windows-tools.iso ]; then
    echo_err "Cannot find Qubes Windows Tools ISO. Exiting..."
fi

# Unpack latest QWT into auto-qwt
qwt_iso_loop="$(mount_loop /usr/lib/qubes/qubes-windows-tools.iso)"
if [ -z "$qwt_iso_loop" ]; then
    echo_err "Failed to create loop device for /usr/lib/qubes/qubes-windows-tools.iso. Exiting..."
    exit 1
fi

qwt_iso_mntpoint="$(mktemp -d)"
if ! sudo mount "/dev/$qwt_iso_loop" "$qwt_iso_mntpoint" >/dev/null 2>&1; then
    echo_err "Failed to mount loop device for /usr/lib/qubes/qubes-windows-tools.iso. Exiting..."
    exit 1
fi

# Copy original content into local folder
cp -r "$qwt_iso_mntpoint/." "auto-qwt/installer"

# Create auto-qwt media
genisoimage -input-charset utf-8 -JR -o "$localdir/auto-qwt.iso" "auto-qwt"
