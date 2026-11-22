#!/bin/sh
# Runs a lock writer, and expects the file it was told to write.
set -eu

BUILD_WORKSPACE_DIRECTORY="$TEST_TMPDIR" "$1"
written="$TEST_TMPDIR/a \$(echo b) 'c'.json"
if [ "$(cat "$written")" = "{}" ]; then
    echo PASS
else
    echo "FAIL: $written is not the lock file" >&2
    exit 1
fi
