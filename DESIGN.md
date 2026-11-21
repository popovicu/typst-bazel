# Design

The decisions behind rules_typst, and why. Edited in place as they
change.

## Typst is downloaded, not built

The toolchain is the binary the Typst project publishes for each release
on GitHub, pinned by SHA-256 in `typst/private/versions.bzl`.

Why: building Typst from source would pull a Rust toolchain and a few
hundred crates into every module that wants a PDF. The published Linux
binaries are statically linked, so one archive per processor runs on any
distribution.

What it costs: only machines Typst publishes for can run the build, and
a release has to be added to the table before it can be chosen. GitHub
publishes the hashes; nothing signs them.

## The root module's version wins

Every module can name a Typst version. All of them become toolchains,
the root module's first, and toolchain resolution takes the first that
runs on the machine.

Why: a document's output depends on the Typst that compiled it (the
embedded fonts change between releases), so whoever owns the build should
decide, the way they decide the version of any other dependency.

## A toolchain is one executable

`typst_toolchain` takes the `typst` executable and its version, and
nothing else. Fonts, packages, and flags belong to the document being
compiled, not to the compiler.

Why: it keeps a hand-made toolchain (a patched Typst, a build from
source) to two attributes.
