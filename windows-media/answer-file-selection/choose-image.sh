#!/bin/bash

# Test for 4-bit color (16 colors)
if [ "0$(tput colors 2> /dev/null)" -ge 16 ]; then
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

usage() {
    echo "Usage: ${0} wim [image]"
}

for arg in "$@"; do
    if [ "$arg" == "-h" ] ||  [ "$arg" == "--help" ]; then
        usage
        exit
    fi
done

if [ "$#" != "1" ] && [ "$#" != "2" ]; then
    usage >&2
    exit 1
fi

wim="$1"
image="$2"

if ! [ -f "$wim" ]; then
    echo -e "${RED}[!]${NC} WIM file not found: $wim" >&2
    exit 1
fi

trap exit ERR

wiminfo="$(wiminfo "$wim")"
num_of_images="$(echo "$wiminfo" | grep "^Image Count: " | cut -d : -f 2 | sed 's/^ *//g')"

# If no image is supplied on the command-line we will list them and ask the user which one they want to use
if ! [ "$image" ]; then
    echo -e "${BLUE}[i]${NC} Detecting editions of Windows on media..." >&2
    image_display_names="$(echo "$wiminfo" | grep "^Display Name: " | cut -d : -f 2 | sed 's/^ *//g')"

    if [ "$num_of_images" -lt 1 ]; then
        echo -e "${RED}[!]${NC} No images found in WIM! Is this valid Windows media?" >&2
        exit 1
    elif [ "$num_of_images" == 1 ]; then
        echo -e "${BLUE}[i]${NC} Using only available image: $image_display_names" >&2
        image="$image_display_names"
    else
        # Print numbered list of all images
        for (( i=0; i < "$num_of_images"; i++ )); do
            read -r image_display_name
            echo "$((i + 1))) $image_display_name" >&2
        done <<< "$image_display_names"

        # Ask user for input
        read -rp "Please select which edition of Windows to install: " image
    fi
fi

# Validate index/name (image can represent either)
image_names="$(echo "$wiminfo" | grep "^Name: " | cut -d : -f 2 | sed 's/^ *//g')"

if [[ "$image" =~ ^[0-9]+$ ]]; then
    # Images in WIM use a 1-based index
    if [ "$image" -le "$num_of_images" ] && [ "$image" -gt 0 ]; then
        # Map image index to the corresponding name
        image_name="$(echo "$image_names" | sed -n "$image p")"
    else
        echo -e "${RED}[!]${NC} Image index does not exist: $image" >&2
        exit 1
    fi
else
    if ! echo "$image_names" | grep -Fx -- "$image"; then
        echo -e "${RED}[!]${NC} Image name does not exist: $image" >&2
        exit 1
    fi
fi

echo "$image_name"
