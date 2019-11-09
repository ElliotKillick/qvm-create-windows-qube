#!/bin/bash

iso_device="$(udisksctl loop-setup -f qwt-installer.iso)"
iso_device="${iso_device#Mapped file * as }"
iso_device="${iso_device%.}"

# Fix race condition where disk tries to mount before finishing setup
until iso_mntpoint="$(udisksctl mount -b "$iso_device")"; do
    sleep 1
done
iso_mntpoint="${iso_mntpoint#Mounted * at }"
iso_mntpoint="${iso_mntpoint%.}"

# Unpack installer into auto-qwt
cp -r "$iso_mntpoint/." "auto-qwt/installer"

udisksctl unmount -b "$iso_device"
udisksctl loop-delete -b "$iso_device"
