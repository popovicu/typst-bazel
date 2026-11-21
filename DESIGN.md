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

## A document compiles from a tree made for it

Typst reads from one directory, the project root: a path is relative to
the file that names it, or absolute from the root, and nothing outside
the root can be read. Bazel keeps sources and generated files in
different trees. So `typst_document` builds a root of its own,
`<name>.root`, with each input symlinked at the path it has in the
repository, and compiles there.

Why: the document reads generated files exactly as it reads sources, and
the paths it writes are the ones that work when Typst is run by hand at
the top of the repository, for files that are checked in.

It also keeps the build honest without a sandbox: the tree holds the
declared inputs and nothing else, so an undeclared file is not found
under any execution strategy.

What it costs: one symlink action per input, which run no process. Files
of another repository have no path in this one and are refused; packages
are how Typst shares across projects.

## The main file is a stub on standard input

Typst resolves symlinks in the path of the main file, then refuses it if
the result is outside the root. Bazel gives an action symlinks only, in
a sandbox or out of one, so the document's own main file is always
refused. Other files are not checked this way.

So Typst compiles a one-line main file that includes the real one, read
from standard input, where there is no path to resolve:

    #include "/doc/report.typ"

The output is byte for byte what compiling `report.typ` directly gives,
and errors still point into the real files, with one more line of
traceback for the stub.

Why not a wrapper program that copies the main file into place: it would
have to be compiled, which puts a Go or Rust toolchain in every build
that wants a PDF. The price of the stub is a shell, used for one
redirection and nothing else.

## An action never downloads

Typst downloads a `@preview` package it cannot find, and has no flag to
turn that off. The action asks Bazel for a sandbox without network, and
sets a proxy nobody listens on, so the download fails where there is no
sandbox too.

Why: an input fetched during an action is one Bazel never hashed.
