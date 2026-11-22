# To revisit

Work we have decided to do later, and decisions that are fine for now but
provisional. Delete an entry once it is done or resolved; `DESIGN.md`
records the outcome.

# Planned work

## Bundles

Typst can write a bundle: several files of any format from one source,
which names them itself, as a website of many pages would. Its output
would be a directory, as a file per page is. Typst calls bundles
unfinished, more so than HTML.

## Watching

`typst watch` recompiles as files change and serves a preview, but it
wants the real source tree, not a tree of symlinks made for one action.
A `bazel run` target could start it at the top of the repository with
the document's fonts and packages.

## Comparing with the rules in the registry

The Bazel Central Registry has a `rules_typst` already, from
`periareon/rules_typst`. Once these rules do what we want of them, set
the two side by side: what each can build, what each needs on the
machine and in the build, how each pins Typst and packages, and how
they behave on the same documents. This module also shares that one's
name, which matters the day it is published.

# Provisional decisions

Each says what we do today, why it is good enough, and what would make us
change it.

## Linux has not been run

Today: the rules have been run on macOS on Apple silicon, in Bazel's
sandbox and outside it. Linux is meant to work the same way: its
releases are in the table, and nothing in the rules asks which of the
two it is on. Each Linux release has been downloaded through Bazel: the
hashes match and `typst` is where the rules look for it. No document
has been compiled there.

Revisit when: there is a Linux machine to run `bazel test //...` on.
Likely answer: run the tests on both in continuous integration, and
delete this entry.

## Packages are pinned by the hash of the archive

Today: the lock file holds the SHA-256 of each package's `.tar.gz`, as
Typst Universe served it when the package was pinned.

Good enough because: Universe builds its archives reproducibly now, and
the ones tried have kept their bytes for months.

Revisit when: a pinned package fails its hash and its contents have not
changed. Universe rebuilds every archive when it deploys and promises
nothing about their bytes; early in 2025 they did change. Likely answer:
pin a hash of the unpacked files instead.

## Packages are symlinked for each document

Today: every file of every package a document imports gets a symlink
action, in that document's own tree.

Good enough because: symlink actions run no process, and a package is
tens of files.

Revisit when: analysis of many documents that share large packages is
slow. Likely answer: point Typst at the `@preview` repository directly,
which is already laid out by name and version, and keep the tree for
packages of the repository.

## The date is written in the BUILD file

Today: a document's date is the `date` attribute, 1970 if there is none.

Good enough because: a date that changes by itself would rebuild the
document every day, and a letter or a resume wants a date someone chose.

Revisit when: a document should carry the day it was built. Likely
answer: an attribute that takes the date from Bazel's `--stamp`.

## Typst uses every processor

Today: Typst lays out with as many threads as the machine has, while
Bazel counts the action as one. Many documents at once ask for more
processors than there are.

Good enough because: documents compile in well under a second.

Revisit when: a build of many large documents is slower in parallel than
it should be. `--jobs` sets the thread count; whether it can change the
output is not something Typst promises either way.
