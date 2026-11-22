"""Repositories that hold Typst releases and offer them as toolchains."""

load(":versions.bzl", "PLATFORMS")

_RELEASE_BUILD = """\
load("{toolchain_bzl}", "typst_toolchain")

typst_toolchain(
    name = "toolchain",
    typst = "typst",
    version = "{version}",
    visibility = ["//visibility:public"],
)
"""

def _typst_release_impl(rctx):
    archive = "typst-" + rctx.attr.triple
    rctx.download_and_extract(
        url = "https://github.com/typst/typst/releases/download/v{}/{}.tar.xz".format(
            rctx.attr.version,
            archive,
        ),
        sha256 = rctx.attr.sha256,
        strip_prefix = archive,
    )
    rctx.file("BUILD.bazel", _RELEASE_BUILD.format(
        toolchain_bzl = Label("//typst:toolchain.bzl"),
        version = rctx.attr.version,
    ))

typst_release = repository_rule(
    implementation = _typst_release_impl,
    doc = "One Typst release, for one kind of machine.",
    attrs = {
        "version": attr.string(mandatory = True),
        "triple": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
    },
)

_TOOLCHAIN = """\
toolchain(
    name = "{name}",
    exec_compatible_with = {constraints},
    toolchain = "@{name}//:toolchain",
    toolchain_type = "{toolchain_type}",
)
"""

def _typst_toolchains_impl(rctx):
    # Naming a release here does not fetch it: Bazel downloads only the
    # one whose constraints match the machine running the build.
    rctx.file("BUILD.bazel", "\n".join([
        _TOOLCHAIN.format(
            name = name,
            constraints = ["@platforms//" + c for c in PLATFORMS[triple]],
            toolchain_type = Label("//typst:toolchain_type"),
        )
        for name, triple in rctx.attr.releases.items()
    ]))

typst_toolchains = repository_rule(
    implementation = _typst_toolchains_impl,
    doc = "Offers releases as toolchains. Earlier ones win.",
    attrs = {
        "releases": attr.string_dict(
            doc = "Repository name of each release, to its target triple.",
            mandatory = True,
        ),
    },
)
