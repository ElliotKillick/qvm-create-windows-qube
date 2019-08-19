#!/bin/bash

if command -v dnf; then
    sudo dnf -y install genisoimage
else
    sudo DEBIAN_FRONTEND=noninteractive apt-get install genisoimage
fi
