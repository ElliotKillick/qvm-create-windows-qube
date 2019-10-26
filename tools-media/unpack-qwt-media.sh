#!/bin/bash

iso_device="$(udisksctl loop-setup -f qubes-windows-tools.iso)"
iso_device="${iso_device#Mapped file * as }"
iso_device="${iso_device%.}"

# Fix race condition where disk tries to mount before finishing setup
until iso_mntpoint="$(udisksctl mount -b "$iso_device")"; do
    sleep 1
done
iso_mntpoint="${iso_mntpoint#Mounted * at }"
iso_mntpoint="${iso_mntpoint%.}"

# Unpack installer into auto-tools
cp -r "$iso_mntpoint/." "auto-tools/qubes-windows-tools/installer"

udisksctl unmount -b "$iso_device"
udisksctl loop-delete -b "$iso_device"
