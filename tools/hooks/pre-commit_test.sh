#!/bin/sh
# Runs the pre-commit hook against a scratch git repository.
set -eu

hook="$PWD/$1"
repo="$TEST_TMPDIR/repo"
mkdir -p "$repo"
cd "$repo"
git init -q

lines() { seq "$1" > "$2"; }

expect() {  # expect <pass|fail> <description>
    if TYPST_BAZEL_COMMIT_LIMIT=10 sh "$hook" 2>/dev/null; then got=pass; else got=fail; fi
    if [ "$got" != "$1" ]; then
        echo "FAIL: $2: expected $1, got $got" >&2
        exit 1
    fi
}

lines 10 small.txt && git add small.txt
expect pass "change at the limit"

lines 11 big.txt && git add big.txt
expect fail "change over the limit"

git rm -q --cached big.txt
mkdir -p a/testdata && lines 50 a/testdata/golden.json && git add a/testdata
expect pass "goldens are excluded"

lines 50 MODULE.bazel.lock && git add MODULE.bazel.lock
expect pass "lockfiles are excluded"

mkdir -p b && lines 50 b/typst.lock.json && git add b
lines 50 typst.lock.json && git add typst.lock.json
expect pass "lock files of packages are excluded"

echo PASS
