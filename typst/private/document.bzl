"""The rule that compiles a document."""

load(":providers.bzl", "TypstLibraryInfo", "TypstPackageInfo")

def _root_path(ctx, file):
    """Where a file sits under the project root: its path in the repository."""
    if file.owner.repo_name != ctx.label.repo_name:
        fail("{} is in another repository, which {} cannot read by path".format(file.owner, ctx.label))
    path = file.short_path
    if path.startswith("../"):
        path = path.split("/", 2)[2]
    return path

def _seconds(ctx):
    """The document's date, as seconds since 1970, which is how Typst takes it."""
    parts = ctx.attr.date.split("-")
    if [len(part) for part in parts] != [4, 2, 2] or not "".join(parts).isdigit():
        fail("date {} of {} is not a YYYY-MM-DD".format(repr(ctx.attr.date), ctx.label))
    year, month, day = [int(part) for part in parts]
    leap = year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
    lengths = [31, 29 if leap else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if year < 1970 or month not in range(1, 13) or day not in range(1, lengths[month - 1] + 1):
        fail("date {} of {} is not a day since 1970".format(repr(ctx.attr.date), ctx.label))

    # Days since 1970 by counting from March 1, so that a leap day is the
    # last day of its year.
    year -= 1 if month <= 2 else 0
    day_of_year = (153 * (month + (-3 if month > 2 else 9)) + 2) // 5 + day - 1
    days = year * 365 + year // 4 - year // 100 + year // 400 + day_of_year - 719468
    return days * 86400

def _typst_document_impl(ctx):
    typst = ctx.toolchains["//typst:toolchain_type"].typst
    name = ctx.label.name

    # The project root: every file at its path in the repository, sources
    # and generated files alike, because Typst reads from one tree only.
    sources = {}
    libraries = [dep[TypstLibraryInfo] for dep in ctx.attr.deps if TypstLibraryInfo in dep]
    for file in depset([ctx.file.main] + ctx.files.srcs, transitive = [library.files for library in libraries]).to_list():
        path = _root_path(ctx, file)
        if path in sources:
            fail("{} has two files at {}".format(ctx.label, path))
        sources[path] = file
    main = _root_path(ctx, ctx.file.main)

    # Fonts get a tree too, so that Typst finds these and no others.
    fonts = {
        file.short_path.removeprefix("../"): file
        for file in depset(
            ctx.files.fonts,
            transitive = [library.fonts for library in libraries],
        ).to_list()
    }

    # And packages, where Typst looks for them: namespace/name/version.
    packages = {}
    for package in depset(transitive = [library.packages for library in libraries] + [
        dep[TypstPackageInfo].packages
        for dep in ctx.attr.deps
        if TypstPackageInfo in dep
    ]).to_list():
        for file in package.files.to_list():
            path = "{}/{}".format(package.spec, file.short_path.removeprefix(package.prefix))
            if path in packages:
                fail("{} gets @{} from two targets".format(ctx.label, package.spec))
            packages[path] = file

    # Each tree is named for the paths in it. Outside a sandbox Typst sees
    # whatever earlier builds left in a directory, and a directory with
    # another name is one they left nothing in.
    trees = {"root": sources, "fonts": fonts, "packages": packages}
    key = "%x" % (hash(repr([sorted(tree) for tree in trees.values()])) % 0x100000000)
    staged = []
    for kind, files in trees.items():
        for path, file in files.items():
            # A directory is what a document with a file per page writes.
            declare = ctx.actions.declare_directory if file.is_directory else ctx.actions.declare_file
            staged.append(declare("{}.{}.{}/{}".format(name, key, kind, path)))
            ctx.actions.symlink(output = staged[-1], target_file = file)

    # Typst refuses a main file that is a symlink out of the root, and
    # Bazel hands an action nothing but symlinks. So the main file is this
    # stub, on standard input.
    stub = ctx.actions.declare_file(name + ".stub.typ")
    beside = "{}.{}".format(stub.path.removesuffix(".stub.typ"), key)
    quoted = main.replace("\\", "\\\\").replace('"', '\\"')
    ctx.actions.write(stub, '#include "/{}"\n'.format(quoted))

    if ctx.attr.file_per_page and ctx.attr.format not in ["png", "svg"]:
        fail("{} is a {}, which is one file however many pages".format(ctx.label, ctx.attr.format))
    if ctx.attr.file_per_page:
        # How many pages is known only once Typst has run, so the output
        # is a directory. Typst numbers the files: 1.png, or 01.png of 12.
        output = ctx.actions.declare_directory(name + ".pages")
        destination = "{}/{{0p}}.{}".format(output.path, ctx.attr.format)
    else:
        output = ctx.actions.declare_file("{}.{}".format(name, ctx.attr.format))
        destination = output.path
    for mark in ["{p}", "{0p}", "{t}"]:
        if mark in output.path and ctx.attr.format in ["png", "svg"]:
            fail("{} has {} in its path, which Typst takes for a page number".format(ctx.label, mark))
    args = ctx.actions.args()
    args.add_all([typst, stub])
    args.add("compile")
    args.add("--root", beside + ".root")
    args.add("--ignore-system-fonts")
    args.add("--creation-timestamp", str(_seconds(ctx)))

    # Both of the places Typst looks, so that it never looks on the host.
    args.add("--package-path", beside + ".packages")
    args.add("--package-cache-path", beside + ".packages")
    if fonts:
        args.add("--font-path", beside + ".fonts")
    for key, value in ctx.attr.inputs.items():
        if "=" in key:
            fail("input {} of {} has = in its name".format(repr(key), ctx.label))
        args.add("--input", "{}={}".format(key, value))
    args.add("--format", ctx.attr.format)
    if ctx.attr.format == "html":
        # Typst calls its HTML unfinished, and says so on every build.
        args.add("--features", "html")
    if ctx.attr.ppi < 1:
        fail("ppi {} of {} is not a number of pixels".format(ctx.attr.ppi, ctx.label))
    if ctx.attr.format == "png":
        args.add("--ppi", str(ctx.attr.ppi))
    args.add("-")
    args.add(destination)
    ctx.actions.run_shell(
        command = 'typst="$1"; stub="$2"; shift 2; exec "$typst" "$@" < "$stub"',
        arguments = [args],
        inputs = staged + [stub],
        tools = [typst],
        outputs = [output],
        mnemonic = "TypstCompile",
        progress_message = "Compiling %{label}",
        toolchain = "//typst:toolchain_type",
        # A package that is not there is an error, not a download: the
        # sandbox has no network, and outside one this proxy is nobody.
        execution_requirements = {"block-network": "1"},
        env = {"ALL_PROXY": "http://127.0.0.1:1"},
    )
    return [DefaultInfo(files = depset([output]))]

typst_document = rule(
    implementation = _typst_document_impl,
    doc = "Compiles a Typst document to <name>.pdf, or to another format.",
    attrs = {
        "main": attr.label(
            doc = "The file Typst compiles.",
            mandatory = True,
            allow_single_file = [".typ"],
        ),
        "srcs": attr.label_list(
            doc = "Every other file the document reads by path: what it " +
                  "imports and includes, images, data. Each sits where it " +
                  "is in the repository, so /a/b.typ is //a:b.typ.",
            allow_files = True,
        ),
        "deps": attr.label_list(
            doc = "Libraries the document reads from, and packages it " +
                  "imports.",
            providers = [[TypstLibraryInfo], [TypstPackageInfo]],
        ),
        "format": attr.string(
            doc = "What to write, as <name>.<format>. A png or an svg " +
                  "is one page, so the document must have only one, " +
                  "unless file_per_page is set.",
            default = "pdf",
            values = ["pdf", "html", "svg", "png"],
        ),
        "file_per_page": attr.bool(
            doc = "Write a png or an svg of each page, into the " +
                  "directory <name>.pages, named by page number.",
        ),
        "ppi": attr.int(
            doc = "Pixels per inch of a png.",
            default = 144,
        ),
        "inputs": attr.string_dict(
            doc = "Strings the document reads as sys.inputs.",
        ),
        "date": attr.string(
            doc = "The day the document says it was made, as YYYY-MM-DD: " +
                  "the date in the PDF, and datetime.today().",
            default = "1970-01-01",
        ),
        "fonts": attr.label_list(
            doc = "Font files the document may use, besides the fonts " +
                  "inside Typst. Fonts of the machine are never used.",
            allow_files = [".ttf", ".otf", ".ttc", ".otc"],
        ),
    },
    toolchains = ["//typst:toolchain_type"],
)
