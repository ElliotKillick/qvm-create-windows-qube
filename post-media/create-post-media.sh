#!/bin/bash

[[ "$DEBUG" == 1 ]] && set -x
localdir="$(readlink -f "$(dirname "$0")")"
scriptsdir="$(readlink -f "$localdir/../scripts")"

# shellcheck source=scripts/common.sh
source "$scriptsdir/common.sh"

echo_info "Preparing default post ISO..."
genisoimage -input-charset utf-8 -JR -o "$localdir/post.iso" "content"
