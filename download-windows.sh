#!/bin/bash

trap 'exit' ERR

scurl() {
    curl --tlsv1.2 --proto =https "$@"
}

download_microsoft_com_key="sha256//2e0F/Ardt/GQmXeDy1wheisQhjSImsJtf1rIekoQE7E="

echo "Downloading Windows ISO..." >&2
cd "windows-media/isos" || exit
scurl --pinnedpubkey "$download_microsoft_com_key" "https://download.microsoft.com/download/5/1/9/5195A765-3A41-4A72-87D8-200D897CBE21/7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_ULTIMATE_x64FRE_en-us.iso" -O

echo "Verifying integrity..." >&2
if ! sha256sum -c SHA256SUMS; then
    echo "The downloaded media did not match the expected hash! This means either the media was corrupted during download or that is has been maliciously modified! Please re-attempt the download and do not use the bad media." >&2
    exit 1
fi

echo "Successfully downloaded and verified integrity of Windows media!"
