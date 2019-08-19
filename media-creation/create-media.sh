#!/bin/bash

# Get ISO: https://www.heidoc.net/joomla/technology-science/microsoft/67-microsoft-windows-and-office-iso-download-tool
# Generate answer file: https://www.windowsafg.com (Must use key provided from https://www.windowsafg.com/keys.html or your own, otherwise you will get a error during installation, the keys there are the default keys because for legal reasons even unregistered versions need keys. For example, when you press "skip" on the section to enter a product key in a manual installation one of the default keys from that link are actually used. The key used can be seen with NirSoft ProduKey)
# Answer file templates: https://github.com/boxcutter/windows/tree/master/floppy

# Test for 4-bit color (16 colors)
if [ "0$(tput colors 2> /dev/null)" -ge 16 ]; then
    RED='\032[0;31m'
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    NC='\033[0m'
fi

usage() { echo -e "Usage: ${0} iso answer_file"; }

for arg in "$@"; do
    if [ "$arg" == "--help" ] ||  [ "$arg" == "-h" ]; then
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

if [ ! -f "$iso" ]; then
    echo -e "${RED}[!]${NC} ISO file $iso not found" >&2
    exit 1
elif [ ! -f "$answer_file" ]; then
    echo -e "${RED}[!]${NC} Answer file $answer_file not found" >&2
    exit 1
fi

cleanup() {
    exit_code="$?"
    
    if [ "$iso_device" ]; then
        echo -e "${BLUE}[i]${NC} Unmounting and deleting original ISO loop device..." >&2
        udisksctl unmount -b "$iso_device"
        udisksctl loop-delete -b "$iso_device"
    fi
    
    if [ "$temp_dir" ]; then
        echo -e "${BLUE}[i]${NC} Deleting temporary folder..." >&2
        chmod -R +w "$temp_dir" # Permissions are originally read-only because ISO is a read-only format
        rm -r "$temp_dir"
    fi
    
    if [ "$exit_code" != 0 ]; then
	if [ "$final_iso_name" ]; then
            echo -e "${BLUE}[i]${NC} Deleting incomplete outputted ISO..." >&2
            rm "$final_iso_name"
        fi
        
	exit "$exit_code"
    fi
}

trap cleanup ERR INT

echo -e "${BLUE}[i]${NC} Creating read-only loop device from ISO..." >&2
iso_device="$(udisksctl loop-setup -f "$iso" | awk '{ print $NF }' | sed 's/.$//')"

sleep 1

echo -e "${BLUE}[i]${NC} Mounting loop device..." >&2
udisksctl mount -b "$iso_device"
iso_mountpoint="$(lsblk -rno NAME,MOUNTPOINT | grep ^"$(echo "$iso_device" | sed 's/.*\///')" | cut -d' ' -f2-)"

echo -e "${BLUE}[i]${NC} Copying ISO loop device contents to temporary folder..." >&2
temp_dir="$(mktemp -dp .)" # tmpfs on /tmp may be too small
cp -r "$iso_mountpoint/." "$temp_dir"

echo -e "${BLUE}[i]${NC} Copying over answer file to Autounattend.xml in temporary folder..." >&2
cp "$answer_file" "$temp_dir/Autounattend.xml"

echo -e "${BLUE}[i]${NC} Creating new ISO..." >&2
dd if="$iso" of="$temp_dir/boot.img" bs=2048 count=8 skip=734 status=progress # count and skip provided by isoinfo (Must use Debian version; Fedora version didn't provide the same level of debug ouput for me)
final_iso_name="$(basename "$iso" | sed 's/\.[^.]*$//')-autounattend.iso"
genisoimage -b boot.img -no-emul-boot -c BOOT.CAT -iso-level 2 -udf -J -l -D -N -joliet-long -relaxed-filenames -R -allow-limited-size -o "$final_iso_name" "$temp_dir" # -R is just to stop genisoimage from complaining that you shouldn't use Joilet without Rock Ridge and -allow-limited-size is for the install.wim which is a huge binary file that can package pre-installed updates among other things that may be too big (past 4GB) which would cause problems if this option wasn't enabled

cleanup

echo -e "${GREEN}[+]${NC} Created automatic Windows installation media $final_iso_name successfully!"
