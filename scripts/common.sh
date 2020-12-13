#!/bin/bash

# Test for 4-bit color (16 colors)
if [ "0$(tput colors 2> /dev/null)" -ge 16 ]; then
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    NC='\033[0m'
fi

echo_info() {
    echo -e "${BLUE}[i]${NC} $*" >&2
}

echo_ok() {
    echo -e "${GREEN}[i]${NC} $*" >&2
}

echo_err() {
    echo -e "${RED}[i]${NC} $*" >&2
}

mount_loop() {
    local iso="$1"
    if [ -e "$iso" ]; then
        DEV_LOOP="$(sudo losetup --show -f -P "$iso" 2>/dev/null)"
        if [[ $DEV_LOOP =~ /dev/loop[0-9]+ ]]; then
            echo "${DEV_LOOP//\/dev\//}"
        fi
    fi
}