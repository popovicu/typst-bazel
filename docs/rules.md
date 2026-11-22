# Rules reference

Every rule, attribute and provider. `README.md` is the guide that shows
them in use; `DESIGN.md` says why they are this way.

The rules are loaded from `@rules_typst//typst:defs.bzl`:

```starlark
load("@rules_typst//typst:defs.bzl", "typst_document", "typst_library", "typst_package")
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
| `srcs` | List of labels | `[]` | Every other file the document reads by path: what it imports and includes, images, data. Source files or outputs of other rules, from any package of this repository. |
| `deps` | List of labels | `[]` | `typst_library` targets whose files the document reads, and `typst_package` targets it imports. |
| `format` | String | `"pdf"` | `"pdf"`, `"html"`, `"svg"` or `"png"`. |
| `file_per_page` | Boolean | `False` | For `"png"` and `"svg"`: write a file of each page into `<name>.pages`, named by page number and padded so they sort (`1.png`, or `01.png` of twelve). An error with the other formats. |
| `ppi` | Integer | `144` | Pixels per inch of a PNG. |
| `inputs` | Dictionary of strings | `{}` | What the document reads as `sys.inputs`. A key cannot contain `=`. |
| `date` | String | `"1970-01-01"` | The day the document says it was made, as `YYYY-MM-DD`: the creation date in a PDF, and `datetime.today()`. |
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
