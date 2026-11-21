"""The module extension that chooses the Typst a build compiles with."""

load("//typst/private:repositories.bzl", "typst_release", "typst_toolchains")
load("//typst/private:universe.bzl", "resolve_packages", "typst_universe")
load("//typst/private:versions.bzl", "VERSIONS")

def _typst_impl(mctx):
    # The root module comes first, so the version it names wins.
    versions = []
    for module in mctx.modules:
        for tag in module.tags.toolchain:
            if tag.version not in VERSIONS:
                fail("Typst {} is not one of {}".format(tag.version, VERSIONS.keys()))
            if tag.version not in versions:
                versions.append(tag.version)
    if not versions:
        fail("No Typst version is chosen. Add typst.toolchain(version = ...) to MODULE.bazel.")

    releases = {}
    for version in versions:
        for triple, sha256 in VERSIONS[version].items():
            name = "typst_{}_{}".format(version, triple).replace(".", "_").replace("-", "_")
            typst_release(name = name, version = version, triple = triple, sha256 = sha256)
            releases[name] = triple
    typst_toolchains(name = "typst_toolchains", releases = releases)

    resolved = resolve_packages(mctx)
    typst_universe(
        name = "preview",
        packages = resolved.packages,
        deps = resolved.deps,
        unlocked = resolved.unlocked,
        lock_file = resolved.lock_file,
        lock = resolved.lock,
    )
    return mctx.extension_metadata(reproducible = not resolved.unlocked)

typst = module_extension(
    implementation = _typst_impl,
    tag_classes = {
        "toolchain": tag_class(
            doc = "Compile with this Typst release.",
            attrs = {"version": attr.string(mandatory = True)},
        ),
        "package": tag_class(
            doc = "A package of Typst Universe, @preview/name:version, " +
                  "which becomes @preview//name:version.",
            attrs = {
                "name": attr.string(mandatory = True),
                "version": attr.string(mandatory = True),
            },
        ),
        "lock": tag_class(
            doc = "Where the hashes of the module's packages are.",
            attrs = {"file": attr.label(mandatory = True)},
        ),
    },
)
