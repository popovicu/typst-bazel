"""The rule that names files documents read by path."""

load(":providers.bzl", "TypstLibraryInfo", "TypstPackageInfo")

def _typst_library_impl(ctx):
    libraries = [dep[TypstLibraryInfo] for dep in ctx.attr.deps if TypstLibraryInfo in dep]
    files = depset(ctx.files.srcs, transitive = [library.files for library in libraries])
    fonts = depset(ctx.files.fonts, transitive = [library.fonts for library in libraries])
    packages = depset(transitive = [library.packages for library in libraries] + [
        dep[TypstPackageInfo].packages
        for dep in ctx.attr.deps
        if TypstPackageInfo in dep
    ])
    return [
        DefaultInfo(files = files),
        TypstLibraryInfo(files = files, fonts = fonts, packages = packages),
    ]

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
            doc = "Libraries these files read from, and packages they " +
                  "import.",
            providers = [[TypstLibraryInfo], [TypstPackageInfo]],
        ),
    },
)
