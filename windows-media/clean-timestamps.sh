#!/bin/bash

# Protect against time attacks due to leaking of ISO file metadata

# https://www.whonix.org/wiki/Time_Attacks
# https://www.whonix.org/wiki/Metadata

# Run given command-line with a fake time stuck at the Unix epoch
# The ISO 9660 and UDF filesystems are embedded with creation timestamps which must be cleaned
# Verify clean ISO timestamps with the dd commands here: https://superuser.com/questions/559031/how-to-find-out-when-a-disc-dvd-has-been-written-burned#answer-559089
run_clean_time_command() {
    cmd=("$@")

    datefudge --static @0 "${cmd[@]}"
}

# Set file timestamp to the Unix epoch
# I think only QEMU would have access to this but as a result of it being buggy (that's why we keep it in a stubdomain), we clean this timestamp too
clean_file_timestamp() {
    file="$1"

    touch --date @0 "$file"
}

# Set file timestamps to the Unix epoch recursively
# Testing proved that these timestamps were kept intact in the newly created ISO and could be seen from within Windows
clean_file_timestamps_recursively() {
    dir="$1"

    find "$dir" -exec touch --date @0 {} +
}
