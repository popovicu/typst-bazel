# Rules reference

Every rule, attribute and provider. `README.md` is the guide that shows
them in use; `DESIGN.md` says why they are this way.

The rules are loaded from `@typst-bazel//typst:defs.bzl`:

```starlark
load("@typst-bazel//typst:defs.bzl", "typst_document", "typst_library", "typst_package")
```

## typst_document

```starlark
typst_document(name, main, srcs, deps, format, file_per_page, ppi, inputs, date, fonts)
```

Compiles one document. `bazel build` of the target writes
`<name>.<format>`, or the directory `<name>.pages` with `file_per_page`.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `main` | Label | required | The `.typ` file Typst compiles. |
| `srcs` | List of labels | `[]` | Every other file the document reads by path: what it imports and includes, images, data. Source files or outputs of other rules, from any package of this repository. An output that is a directory, as `<name>.pages` is, is read by the paths inside it. |
| `deps` | List of labels | `[]` | `typst_library` targets whose files the document reads, and `typst_package` targets it imports. |
| `format` | String | `"pdf"` | `"pdf"`, `"html"`, `"svg"` or `"png"`. |
| `file_per_page` | Boolean | `False` | For `"png"` and `"svg"`: write a file of each page into `<name>.pages`, named by page number and padded so they sort (`1.png`, or `01.png` of twelve). An error with the other formats. |
| `ppi` | Integer | `144` | Pixels per inch of a PNG, at least 1. |
| `inputs` | Dictionary of strings | `{}` | What the document reads as `sys.inputs`. A key cannot contain `=`. |
| `date` | String | `"1970-01-01"` | The day the document says it was made, as `YYYY-MM-DD`: the creation date in a PDF, and `datetime.today()`. A day that is not on the calendar, or is before 1970, is an error. |
| `fonts` | List of labels | `[]` | Font files (`.ttf`, `.otf`, `.ttc`, `.otc`) the document may use, from any repository. |

**What the document can read.** Typst sees one tree, laid out like the
repository, holding `main`, `srcs`, and the files of the libraries in
`deps`. A path that starts with `/` is from the top of the repository;
any other is from the file that names it. Nothing else is there: a file
that is not listed is not found, and neither is a file of another
repository.

**What it cannot reach.** Fonts of the machine, packages in the machine's
Typst cache, and the network. It has the four font families inside
Typst, the fonts named here and in its libraries, and the packages in
`deps`.

**One page or many.** A PDF or an HTML file holds the whole document.
A PNG or an SVG holds one page, so without `file_per_page` Typst refuses
a document that has more.

**HTML.** Typst's HTML export leaves out grids, lines and spacing, and
warns on every build that it is unfinished. A document meant for both
asks `target()` which it is writing for; `examples/resume` does.

**Providers returned:** `DefaultInfo`, whose only file is the output.

## typst_library

```starlark
typst_library(name, srcs, fonts, deps)
```

Files that several documents read by path, with what those files need.
It compiles nothing.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `srcs` | List of labels | `[]` | The files: Typst sources, images, data. |
| `fonts` | List of labels | `[]` | Font files these files set text in. |
| `deps` | List of labels | `[]` | Libraries these files read from, and packages they import. |

A document that names the library in `deps` gets all three, and those of
the libraries it depends on in turn. It reads the files where they are
in the repository: `//shared:style` with `srcs = ["style.typ"]` is
`"/shared/style.typ"`.

**Providers returned:** `DefaultInfo`, `TypstLibraryInfo`

## typst_package

```starlark
typst_package(name, manifest, srcs, namespace, package_name, version, deps)
```

A package in the repository, imported as
`@namespace/package_name:version` by any document or library that names
it in `deps`, in this repository or another.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `manifest` | Label | required | The package's `typst.toml`. Its directory is the package. |
| `srcs` | List of labels | `[]` | The package's other files, in that directory or below it. |
| `namespace` | String | `"local"` | The part after `@` in an import. |
| `package_name` | String | the target's name | The package's name, which must be the one in `typst.toml`. |
| `version` | String | required | Its version, which must be the one in `typst.toml`. |
| `deps` | List of labels | `[]` | Packages this one imports. |

The name and the version are written twice, here and in `typst.toml`,
because a rule cannot read a file while Bazel is still deciding what to
build. Typst reports a mismatch when the package is imported.

A document can have one target for each `namespace/name/version`. Two
that claim the same one are an error.

**Providers returned:** `DefaultInfo`, `TypstPackageInfo`

## The module extension

```starlark
typst = use_extension("@typst-bazel//typst:extensions.bzl", "typst")
```

### typst.toolchain

```starlark
typst.toolchain(version)
```

Chooses the Typst release documents compile with. `version` is one of
those in `typst/private/versions.bzl`. Some module must choose one. When
several do, the root module's choice wins.

The release is downloaded for the machine that runs the build, the first
time something compiles, and checked against a SHA-256. There are
releases for Linux (x86-64, ARM64, ARMv7, RISC-V) and macOS (x86-64,
ARM64).

### typst.package

```starlark
typst.package(name, version)
```

Asks for a package of Typst Universe. `@preview/name:version` in Typst
is then the label `@preview//name:version`.

### typst.lock

```starlark
typst.lock(file)
```

The label of the JSON file that pins the module's packages. A module
with a `typst.package` needs exactly one. The file need not exist yet:
`bazel run @preview//:lock` writes it.

For each package asked for, and each one those import, the file holds
the SHA-256 of its archive and the packages it imports:

```json
{
    "oxifmt:1.0.0": {
        "deps": [],
        "sha256": "7d17a1fc..."
    }
}
```

### The `@preview` repository

Brought in with `use_repo(typst, "preview")`.

| Target | What it is |
|--------|------------|
| `@preview//name:version` | A package, with every package it imports, however far down. Visible only if a `typst.package` asks for it by name. |
| `@preview//:lock` | Run it to write the root module's lock file: it pins what the file lacks, keeps the hashes it has, and drops what nothing asks for. |
| `@preview//:typst.lock.json` | What that would write, to compare with the file checked in. |

While the root module's lock file lacks a package, no package builds,
and the error names the ones to pin. A module that is not the root must
have every package in its lock file already.

## Running Typst

```bash
bazel run @typst-bazel//typst -- fonts
```

`@typst-bazel//typst` is the chosen release, as an executable.

## Bringing your own Typst

```starlark
load("@typst-bazel//typst:toolchain.bzl", "typst_toolchain")

typst_toolchain(name, typst, version)
```

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `typst` | Label | required | The `typst` executable. |
| `version` | String | required | Its version, as in `0.15.1`. |

Wrap it in a `toolchain()` of type `@typst-bazel//typst:toolchain_type`
and register that in the root module, whose toolchains come ahead of the
downloaded ones. The extension still wants a `typst.toolchain` line.
Rules read `typst`, the executable, and `version` from the toolchain.

## Providers

### TypstLibraryInfo

| Field | Type | Description |
|-------|------|-------------|
| `files` | depset of File | The library's files, and those of the libraries it depends on. |
| `fonts` | depset of File | The font files those need. |
| `packages` | depset of struct | The packages those import, as in `TypstPackageInfo`. |

### TypstPackageInfo

| Field | Type | Description |
|-------|------|-------------|
| `packages` | depset of struct | The package and those it imports. |

Each struct has `spec`, the directory Typst looks for the package in, as
`namespace/name/version`; `files`, a depset of File; and `prefix`, what
to take off a file's `short_path` for its path inside the package.

A rule that returns one of these can stand where a library or a package
does: a rule that generates Typst sources, say.
