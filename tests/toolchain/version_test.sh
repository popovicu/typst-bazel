#!/bin/sh
# Runs the Typst of the build and expects the version MODULE.bazel names.
set -eu

got=$("$1" --version)
case "$got" in
    "typst 0.15.1 "*) echo PASS ;;
    *) echo "FAIL: typst --version printed: $got" >&2; exit 1 ;;
esac
