"""Packages from Typst Universe, as a repository of typst_package targets."""

load(":imports.bzl", "preview_imports")
load(":pins.bzl", "read_pins")

_URL = "https://packages.typst.org/preview/{}-{}.tar.gz"
_INDEX = "https://packages.typst.org/preview/index.json"

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
    visibility = {visibility},
    deps = {deps},
)
"""

_UNLOCKED = """
unlocked_package(
    name = "{version}",
    lock_file = {lock_file},
    unlocked = {unlocked},
    visibility = ["//visibility:public"],
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

# A package nobody asked for is here because another imports it, and goes
# when that one does. Only the packages here may name it.
_ASKED = ["//visibility:public"]
_IMPORTED = ["//:__subpackages__"]

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
        builds.setdefault(name, []).append(_UNLOCKED.format(
            version = version,
            lock_file = repr(rctx.attr.lock_file),
            unlocked = rctx.attr.unlocked,
        ) if rctx.attr.unlocked else _PACKAGE.format(
            name = name,
            version = version,
            visibility = _ASKED if spec in rctx.attr.asked else _IMPORTED,
            deps = [_label(dep) for dep in rctx.attr.deps[spec]],
        ))
    header = 'load("{}", "typst_package")\nload("{}", "unlocked_package")\n'.format(
        Label("//typst:defs.bzl"),
        Label(":lock.bzl"),
    )
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
        "asked": attr.string_list(doc = "The packages a module asks for by name."),
        "deps": attr.string_list_dict(doc = "name:version, to the packages it imports."),
        "unlocked": attr.string_list(doc = "The packages the lock file lacks."),
        "lock_file": attr.string(doc = "The root module's lock file, as a path."),
        "lock": attr.string(doc = "What that file should say."),
    },
)

def _published(mctx):
    """Every name:version in Typst Universe, or None if it cannot be asked."""
    index = mctx.path("resolve/index.json")
    if not index.exists and not mctx.download(url = _INDEX, output = index, allow_fail = True).success:
        return None
    return ["{}:{}".format(package["name"], package["version"]) for package in json.decode(mctx.read(index))]

def _resolve(mctx, spec, required):
    """Downloads a package to learn its hash and what it imports."""
    name, version = spec.split(":")
    directory = "resolve/{}/{}".format(name, version)
    result = mctx.download_and_extract(
        url = _URL.format(name, version),
        output = directory,
        type = "tar.gz",
        allow_fail = True,
    )
    published = None if result.success else _published(mctx)
    if published != None and spec not in published and not required:
        # buildifier: disable=print
        print("@preview/{} is named by a package, and is not one".format(spec))
        return None
    if published != None and spec not in published:
        fail("@preview/{} is not a package of Typst Universe".format(spec))
    if not result.success:
        # A package, or there is no telling: either way it is the network.
        fail(("@preview/{} could not be downloaded. Bazel keeps that answer " +
              "until it restarts: bazel shutdown, then run this again.").format(spec))
    found = []
    directories = [mctx.path(directory)]
    for i in range(100000):
        if i == len(directories):
            break
        for entry in directories[i].readdir():
            if entry.is_dir:
                directories.append(entry)
            elif entry.basename.endswith(".typ"):
                found.extend(preview_imports(mctx.read(entry)))
    deps = sorted({dep: None for dep in found if dep != spec}.keys())
    return {"deps": deps, "sha256": result.sha256}

def resolve_packages(mctx):
    """Finds what each module asks for, and all that those import.

    A package comes from the module's lock file. One that the root
    module's lock file lacks is downloaded and read instead.

    Returns:
      A struct of what typst_universe takes.
    """
    packages = {}
    asked_for = []
    deps = {}
    unlocked = []
    lock_file = ""
    lock = ""
    for module in mctx.modules:
        todo = ["{}:{}".format(tag.name, tag.version) for tag in module.tags.package]

        # A module that dropped its last package still has a file to empty.
        if not todo and not module.tags.lock:
            continue
        if len(module.tags.lock) != 1:
            fail("{} asks for packages, so it needs one typst.lock(file = ...)".format(module.name))
        file = module.tags.lock[0].file

        # Watched whether or not it exists: writing it changes the answer.
        mctx.watch(file)
        pinned = read_pins(mctx.read(file)) if mctx.path(file).exists else {}
        if pinned == None:
            fail("{} is not a lock file as bazel run @preview//:lock writes one. Delete it, and run that.".format(file))
        asked = len(todo)
        asked_for.extend(todo)
        for i in range(100000):
            if i == len(todo):
                break
            spec = todo[i]
            entry = pinned.get(spec)
            if not entry and not module.is_root:
                fail("@preview/{} is not in {}".format(spec, file))
            if not entry:
                entry = _resolve(mctx, spec, required = i < asked)
                if not entry:
                    continue
                unlocked.append(spec)
            if packages.setdefault(spec, entry["sha256"]) != entry["sha256"]:
                fail("@preview/{} has two hashes, one of them in {}".format(spec, file))
            if deps.setdefault(spec, entry["deps"]) != entry["deps"]:
                fail("@preview/{} imports other packages in {} than in another lock file".format(spec, file))
            todo.extend([dep for dep in deps[spec] if dep not in todo])

        # A package that does not exist was named in an example, not imported.
        found = sorted([spec for spec in todo if spec in packages])
        for spec in found:
            deps[spec] = [dep for dep in deps[spec] if dep in packages]
        if module.is_root:
            lock_file = (file.package + "/" + file.name).removeprefix("/")
            lock = json.encode_indent(
                {spec: {"deps": deps[spec], "sha256": packages[spec]} for spec in found},
                indent = "    ",
            ) + "\n"
    return struct(
        packages = packages,
        asked = asked_for,
        deps = deps,
        unlocked = unlocked,
        lock_file = lock_file,
        lock = lock,
    )
