# rules_typst

Bazel rules for [Typst](https://typst.app): compile documents with a
Typst that Bazel downloads, from inputs Bazel knows about.

> [!WARNING]
> rules_typst is being built. This file describes what works today:
> Bazel downloads Typst. No rule compiles a document yet.

## Choosing a Typst

In `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_typst", version = "...")

typst = use_extension("@rules_typst//typst:extensions.bzl", "typst")
typst.toolchain(version = "0.15.1")
```

Bazel downloads that release for the machine running the build, the
first time something needs it, and checks it against a pinned SHA-256.
Typst from the host is never used. `typst/private/versions.bzl` lists the
releases to choose from.

To run it by hand:

```bash
bazel run @rules_typst//typst -- fonts
```

## Working on the rules

```bash
bazel test //...
```

See `CLAUDE.md` for how changes are made and `DESIGN.md` for why things
are the way they are.
