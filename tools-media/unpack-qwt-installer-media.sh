#!/bin/bash

iso_device="$(udisksctl loop-setup --file qwt-installer.iso)"
iso_device="${iso_device#Mapped file * as }"
iso_device="${iso_device%.}"

# Fix race condition where disk tries to mount before finishing setup
until iso_mntpoint="$(udisksctl mount --block-device "$iso_device")"; do
    sleep 1
done
iso_mntpoint="${iso_mntpoint#Mounted * at }"
iso_mntpoint="${iso_mntpoint%.}"

# Unpack installer into auto-qwt
cp -r "$iso_mntpoint/." "auto-qwt/installer"

udisksctl unmount --block-device "$iso_device"
udisksctl loop-delete --block-device "$iso_device"
