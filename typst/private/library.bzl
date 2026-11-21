"""The rule that names files documents read by path."""

load(":providers.bzl", "TypstLibraryInfo")

def _typst_library_impl(ctx):
    files = depset(
        ctx.files.srcs,
        transitive = [dep[TypstLibraryInfo].files for dep in ctx.attr.deps],
    )
    fonts = depset(
        ctx.files.fonts,
        transitive = [dep[TypstLibraryInfo].fonts for dep in ctx.attr.deps],
    )
    return [DefaultInfo(files = files), TypstLibraryInfo(files = files, fonts = fonts)]

typst_library = rule(
    implementation = _typst_library_impl,
    doc = "Files documents read by path, with the files those need.",
    attrs = {
        "srcs": attr.label_list(
            doc = "The files: Typst sources, images, data.",
            allow_files = True,
        ),
        "fonts": attr.label_list(
            doc = "Font files these files set text in. A document that " +
                  "depends on the library gets them.",
            allow_files = [".ttf", ".otf", ".ttc", ".otc"],
        ),
        "deps": attr.label_list(
            doc = "Libraries these files read from.",
            providers = [TypstLibraryInfo],
        ),
    },
)
