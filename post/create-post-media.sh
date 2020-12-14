#!/bin/bash

[[ "$DEBUG" == 1 ]] && set -x
localdir="$(readlink -f "$(dirname "$0")")"
scriptsdir="$(readlink -f "$localdir/../scripts")"

# shellcheck source=scripts/common.sh
source "$scriptsdir/common.sh"

content="${1:-"$localdir/content"}"

echo_info "Preparing post media from '$content'..."
genisoimage -input-charset utf-8 -JR -o "$localdir/post.iso" "$content"
