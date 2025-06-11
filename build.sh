#!/bin/bash

if [ ${DIB_DEBUG_TRACE:-0} -gt 0 ]; then
    set -x
fi
set -o errexit
set -o nounset
set -o pipefail

# Use current shell path as elements path
export ELEMENTS_PATH="$(dirname "$0")"
export TMPDIR="$(dirname "$0")/tmp"
mkdir -p "$TMPDIR"

if ! command -v diskimage-builder &>/dev/null; then
    pip3 install diskimage-builder
fi

diskimage-builder $@
