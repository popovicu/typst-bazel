#!/bin/sh
# Expects a PDF to contain some bytes: pdf_has_test.sh <pdf> <text>.
#
# A PDF's text is compressed, but its title and the names of its fonts
# are not: "/Title(...)" and "+FontName". So tests have their documents
# compute a title from whatever they mean to check.
set -eu

if grep -a -q -F -- "$2" "$1"; then
    echo PASS
else
    echo "FAIL: $1 does not contain: $2" >&2
    exit 1
fi
