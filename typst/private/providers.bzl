"""What Typst rules tell each other."""

TypstLibraryInfo = provider(
    doc = "Files a document reads by path.",
    fields = {
        "files": "depset of File: the library's files and those of the " +
                 "libraries it depends on.",
        "fonts": "depset of File: the font files those need.",
    },
)
