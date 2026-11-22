# Design

The decisions behind typst-bazel, and why. Edited in place as they
change.

## A name of its own

The module is `typst-bazel`, not `rules_typst` as Bazel rules are
usually named.

Why: the Bazel Central Registry already has a `rules_typst`, from
another project, and a registry holds one module per name.

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

## Linux and macOS, not Windows

The table lists Typst's releases for Linux and macOS and leaves out the
ones for Windows.

Why: nobody here builds on Windows, and the rules lean on a shell, to
compile a document and to write the lock file. A release that is listed
and cannot work is worse than one that is not listed.

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
different trees. So `typst_document` builds a root of its own, with each
input symlinked at the path it has in the repository, and compiles
there.

Why: the document reads generated files exactly as it reads sources, and
the paths it writes are the ones that work when Typst is run by hand at
the top of the repository, for files that are checked in.

It also keeps the build honest without a sandbox: the tree holds the
declared inputs and nothing else, so an undeclared file is not found
under any execution strategy. For that the tree's name carries a hash of
the paths in it, as in `<name>.6583a1e1.root`. Without a sandbox, a
directory keeps the symlinks of earlier builds, so a file taken out of
the rule would still be found in a tree that kept its name. Fonts and
packages get trees named the same way.

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

## A file per page is a directory

With `file_per_page`, the output is the directory `<name>.pages`, and
Typst names the files in it by page number.

Why: Bazel wants every output file named before anything runs, and how
many pages a document has is known only after Typst has laid it out. A
directory is the one output whose contents can wait. It is asked for, not
the default, because one file is easier to use where one page is all
there is: a figure, a preview.

## An action never downloads

Typst downloads a `@preview` package it cannot find, and has no flag to
turn that off. The action asks Bazel for a sandbox without network, and
sets a proxy nobody listens on, so the download fails where there is no
sandbox too.

Why: an input fetched during an action is one Bazel never hashed.

## A package says its name twice

Typst finds a package in a directory named for it,
`namespace/name/version`, and reads the name and version again from the
`typst.toml` inside. Bazel has to lay that directory out before any file
is read, so `typst_package` takes the name and the version as
attributes, beside a manifest that says the same.

Why not write the manifest from the attributes: a package directory with
a real `typst.toml` is one Typst and its editors understand without
Bazel, and one that can be published as it is. Typst refuses a package
whose manifest disagrees with where it was found, so the two cannot
drift apart unnoticed.

Packages are symlinked into a tree per document, as
its files are, and Typst is pointed there for both of the places it
looks, so packages installed on the machine are never seen.

## Packages from Typst Universe are pinned in a file of ours

Typst Universe serves an archive per package version, and nothing else a
build could rely on: no hashes, and no list of what a package imports
(a `typst.toml` has no place to say). The lock file records both. It is
the module extension that reads it, and one repository, `@preview`,
that holds every package in it as a `typst_package`.

Why a file of our own and not Bazel's `MODULE.bazel.lock`: this one is
short, sorted, and reads as what it is in review, a list of packages
with their hashes. It also pins the same way whether or not Bazel's own
lock file is checked in.

Why one repository for all packages: `@preview//cetz:0.5.3` then reads
as `@preview/cetz:0.5.3` does in Typst, and a package can depend on
another by a label in the same repository.

## What a package imports is read from its sources

To pin a package, the extension downloads it and looks through its
`.typ` files for strings that name a package, `"@preview/name:1.2.3"`,
skipping lines that are comments. It does not parse Typst.

Why: the only complete answer is in the sources, and parsing them
properly takes Typst's own parser, which is a program to build. Reading
too much is harmless: a package named in an example and never imported
costs one download. A name that cannot be downloaded, and that Typst
Universe's list of packages does not have, is taken for such an example
and dropped, with a warning. One that the list does have is the network
failing, and stops the lock command: a lock file written without it
would be wrong, and nothing would ever put it right.

Reading too much can also close a circle: a package whose example
imports another that imports it. So a package's target does not depend
on the targets of its imports. It lists the files of every package it
reaches, each a target with no dependencies of its own.

This runs only for packages the lock file lacks. Once they are in the
file, nothing is read and nothing is downloaded without a hash.

## Only a package that was asked for can be named

`@preview` holds every package in the lock file, but only those a
`typst.package` names are visible outside it. The rest are visible to
the packages of `@preview` alone.

Why: a package that is there because another imports it goes when that
one goes, or when it stops importing it. A document that named it would
break in a change that never touched it. Now it fails the first time it
is built, and one line in `MODULE.bazel` settles it.

## A lock file that lacks a package stops the build

When the lock file is incomplete, every package target fails, saying
which packages are not pinned and how to pin them. Only
`bazel run @preview//:lock` works.

Why not go on with the hashes just computed: the build would pass on
whatever the network served that day, on every machine separately, and
nothing would say so. Stopping costs one command, once per change to the
packages.

A module that is not the root must come with a complete lock file,
because nobody building it can write one into it.
