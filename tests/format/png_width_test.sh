#!/bin/sh
# Expects a PNG to be so many pixels wide: png_width_test.sh <png> <width>.
set -eu

# The width is the four bytes after the sixteenth, most significant first.
set -- "$1" "$2" $(od -An -tu1 -j16 -N4 "$1")
width=$(( ($3 << 24) + ($4 << 16) + ($5 << 8) + $6 ))
if [ "$width" -eq "$2" ]; then
    echo PASS
else
    echo "FAIL: $1 is $width pixels wide, not $2" >&2
    exit 1
fi
