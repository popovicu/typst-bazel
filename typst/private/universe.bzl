"""Packages from Typst Universe, as a repository of typst_package targets."""

_URL = "https://packages.typst.org/preview/{}-{}.tar.gz"

_PACKAGE = """
typst_package(
    name = "{version}",
    srcs = glob(
        ["{version}/**"],
        allow_empty = True,
        exclude = ["{version}/typst.toml"],
    ),
    manifest = "{version}/typst.toml",
    namespace = "preview",
    package_name = "{name}",
    version = "{version}",
    visibility = ["//visibility:public"],
    deps = {deps},
)
"""

def _label(spec):
    return "//{}:{}".format(*spec.split(":"))

def _typst_universe_impl(rctx):
    # @preview/cetz:0.5.3 is //cetz:0.5.3 here, its files in cetz/0.5.3.
    builds = {}
    for spec, sha256 in rctx.attr.packages.items():
        name, version = spec.split(":")
        rctx.download_and_extract(
            url = _URL.format(name, version),
            sha256 = sha256,
            output = "{}/{}".format(name, version),
            type = "tar.gz",
        )
        builds.setdefault(name, []).append(_PACKAGE.format(
            name = name,
            version = version,
            deps = [_label(dep) for dep in rctx.attr.deps[spec]],
        ))
    for name, packages in builds.items():
        header = 'load("{}", "typst_package")\n'.format(Label("//typst:defs.bzl"))
        rctx.file(name + "/BUILD.bazel", header + "".join(packages))
    rctx.file("BUILD.bazel", "")

typst_universe = repository_rule(
    implementation = _typst_universe_impl,
    doc = "Packages of Typst Universe, each pinned by the hash of its archive.",
    attrs = {
        "packages": attr.string_dict(doc = "name:version, to the archive's SHA-256."),
        "deps": attr.string_list_dict(doc = "name:version, to the packages it imports."),
    },
)

def locked_packages(mctx):
    """Reads what each module asks for, and all that those import, from its lock.

    Returns the packages and deps that typst_universe takes.
    """
    packages = {}
    deps = {}
    for module in mctx.modules:
        todo = ["{}:{}".format(tag.name, tag.version) for tag in module.tags.package]
        if not todo:
            continue
        if len(module.tags.lock) != 1:
            fail("{} asks for packages, so it needs one typst.lock(file = ...)".format(module.name))
        file = module.tags.lock[0].file
        lock = json.decode(mctx.read(file))
        for i in range(len(todo) + len(lock)):
            if i == len(todo):
                break
            spec = todo[i]
            if spec not in lock:
                fail("@preview/{} is not in {}".format(spec, file))
            if packages.setdefault(spec, lock[spec]["sha256"]) != lock[spec]["sha256"]:
                fail("@preview/{} has two hashes, one of them in {}".format(spec, file))
            deps[spec] = lock[spec]["deps"]
            todo.extend([dep for dep in deps[spec] if dep not in todo])
    return packages, deps
