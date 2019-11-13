#!/bin/bash

if command -v dnf; then
    sudo dnf -y install genisoimage
else
    sudo apt-get -y install genisoimage
fi
