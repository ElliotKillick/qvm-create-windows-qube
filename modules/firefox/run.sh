#!/bin/bash

# Despite speicifying "os=win64" in the URL, 32-bit firefox is still installed by the automatic installer if the 3GB minimum RAM requirement is not met: https://www.mozilla.org/en-US/firefox/windows-64-bit/

dir="../../auto-tools/auto-tools/modules/firefox"
file="firefox-setup.exe"

# If no update installed in past day then update
if [ "$(find $dir -mtime -1 -type f -name $file)" == "" ]; then
    echo "Downloading Firefox..." >&2
    until curl --tlsv1.2 --proto =https --pinnedpubkey "sha256//SnpM0kci03c36PZdxch1BaXo8XKYuZELSLodkakUUOU=;sha256//bxXzdHMdX8KwgkVVKUS2Batet7KI0ipTWn5l12eMthg=" --location "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US" -o "$dir/$file"; do
        echo "Failed to download Firefox! Retrying in 10 seconds..." >&2
        sleep 10
    done
fi
