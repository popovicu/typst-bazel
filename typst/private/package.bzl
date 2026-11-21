"""The rule that makes a package of files in the repository."""

load(":providers.bzl", "TypstPackageInfo")

def _typst_package_impl(ctx):
    # The package is the directory of its manifest, as it is for Typst.
    prefix = ctx.file.manifest.short_path.removesuffix("typst.toml")
    files = [ctx.file.manifest] + ctx.files.srcs
    for file in files:
        if not file.short_path.startswith(prefix):
            fail("{} is not in the directory of {}".format(file.short_path, ctx.file.manifest.short_path))

    package = struct(
        spec = "{}/{}/{}".format(ctx.attr.namespace, ctx.attr.package_name or ctx.label.name, ctx.attr.version),
        prefix = prefix,
        files = depset(files),
    )
    packages = depset(
        [package],
        transitive = [dep[TypstPackageInfo].packages for dep in ctx.attr.deps],
    )
    return [DefaultInfo(files = package.files), TypstPackageInfo(packages = packages)]

typst_package = rule(
    implementation = _typst_package_impl,
    doc = "A Typst package, imported as @namespace/package_name:version.",
    attrs = {
        "manifest": attr.label(
            doc = "The package's typst.toml. Its name and version must " +
                  "be the ones given here.",
            mandatory = True,
            allow_single_file = ["typst.toml"],
        ),
        "srcs": attr.label_list(
            doc = "The package's other files, in the manifest's " +
                  "directory or below it.",
            allow_files = True,
        ),
        "namespace": attr.string(default = "local"),
        "package_name": attr.string(doc = "The target's name, if not given."),
        "version": attr.string(mandatory = True),
        "deps": attr.label_list(
            doc = "Packages this one imports.",
            providers = [TypstPackageInfo],
        ),
    },
)
