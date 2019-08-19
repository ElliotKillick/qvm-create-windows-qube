#!/bin/bash

# The lastest version of QWT is stored in dom0 at: /usr/lib/qubes/qubes-windows-tools.iso

iso_device="$(udisksctl loop-setup -f qubes-windows-tools.iso | awk '{ print $NF }' | sed 's/.$//')"

sleep 1

udisksctl mount -b "$iso_device"
iso_mountpoint="$(lsblk -rno NAME,MOUNTPOINT | grep ^"$(echo "$iso_device" | sed 's/.*\///')" | cut -d' ' -f2-)"

cp -r "$iso_mountpoint/." "../auto-tools/auto-tools/qubes-windows-tools/qubes-windows-tools"

udisksctl unmount -b "$iso_device"
udisksctl loop-delete -b "$iso_device"
