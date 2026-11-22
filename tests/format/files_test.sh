#!/usr/bin/env bash
# Usage: files_test.sh <directory> <name>...
# Passes if the directory holds exactly the files named.
set -euo pipefail

directory="$1"
shift
found="$(ls "$directory" | tr '\n' ' ')"
wanted="$(printf '%s\n' "$@" | sort | tr '\n' ' ')"
if [[ "$found" != "$wanted" ]]; then
  echo "$directory holds: $found" >&2
  echo "wanted: $wanted" >&2
  exit 1
fi
