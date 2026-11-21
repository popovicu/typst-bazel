"""What Typst rules tell each other."""

TypstLibraryInfo = provider(
    doc = "Files a document reads by path.",
    fields = {
        "files": "depset of File: the library's files and those of the " +
                 "libraries it depends on.",
        "fonts": "depset of File: the font files those need.",
    },
)

TypstPackageInfo = provider(
    doc = "Packages a document imports as @namespace/name:version.",
    fields = {
        "packages": "depset of struct: the package and those it imports. " +
                    "Each has spec, the directory Typst looks for it in, " +
                    "as namespace/name/version; files, a depset of File; " +
                    "and prefix, what to take off a file's short_path " +
                    "for its path in the package.",
    },
)
