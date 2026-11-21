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

_ROOT = """\
load("{bzl}", "write_lock")

exports_files(["typst.lock.json"])

write_lock(
    name = "lock",
    lock = {lock},
    lock_file = {lock_file},
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
    header = 'load("{}", "typst_package")\n'.format(Label("//typst:defs.bzl"))
    for name, packages in builds.items():
        rctx.file(name + "/BUILD.bazel", header + "".join(packages))
    rctx.file("typst.lock.json", rctx.attr.lock)
    rctx.file("BUILD.bazel", _ROOT.format(
        bzl = Label(":lock.bzl"),
        lock = repr(rctx.attr.lock),
        lock_file = repr(rctx.attr.lock_file),
    ) if rctx.attr.lock_file else "")

typst_universe = repository_rule(
    implementation = _typst_universe_impl,
    doc = "Packages of Typst Universe, each pinned by the hash of its archive.",
    attrs = {
        "packages": attr.string_dict(doc = "name:version, to the archive's SHA-256."),
        "deps": attr.string_list_dict(doc = "name:version, to the packages it imports."),
        "lock_file": attr.string(doc = "The root module's lock file, as a path."),
        "lock": attr.string(doc = "What that file should say."),
    },
)

def resolve_packages(mctx):
    """Finds what each module asks for, and all that those import.

    All of them have to be in the module's lock file.

    Returns:
      A struct of what typst_universe takes.
    """
    packages = {}
    deps = {}
    lock_file = ""
    lock = ""
    for module in mctx.modules:
        todo = ["{}:{}".format(tag.name, tag.version) for tag in module.tags.package]
        if not todo:
            continue
        if len(module.tags.lock) != 1:
            fail("{} asks for packages, so it needs one typst.lock(file = ...)".format(module.name))
        file = module.tags.lock[0].file
        pinned = json.decode(mctx.read(file))
        for i in range(100000):
            if i == len(todo):
                break
            spec = todo[i]
            entry = pinned.get(spec)
            if not entry:
                fail("@preview/{} is not in {}".format(spec, file))
            if packages.setdefault(spec, entry["sha256"]) != entry["sha256"]:
                fail("@preview/{} has two hashes, one of them in {}".format(spec, file))
            deps[spec] = entry["deps"]
            todo.extend([dep for dep in deps[spec] if dep not in todo])
        found = sorted(todo)
        if module.is_root:
            lock_file = (file.package + "/" + file.name).removeprefix("/")
            lock = json.encode_indent(
                {spec: {"deps": deps[spec], "sha256": packages[spec]} for spec in found},
                indent = "    ",
            ) + "\n"
    return struct(
        packages = packages,
        deps = deps,
        lock_file = lock_file,
        lock = lock,
    )
