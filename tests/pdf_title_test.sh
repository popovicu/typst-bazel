#!/bin/sh
# Expects a PDF to carry a title: pdf_title_test.sh <pdf> <title>.
#
# A PDF's text is compressed and its title is not, so tests have their
# documents compute a title from whatever they mean to check.
set -eu

if grep -a -q -F "/Title($2)" "$1"; then
    echo PASS
else
    echo "FAIL: $1 is not titled: $2" >&2
    exit 1
fi
