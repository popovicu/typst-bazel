"""The rule that compiles a document."""

def _root_path(ctx, file):
    """Where a file sits under the project root: its path in the repository."""
    if file.owner.repo_name != ctx.label.repo_name:
        fail("{} is in another repository, which {} cannot read by path".format(file.owner, ctx.label))
    path = file.short_path
    if path.startswith("../"):
        path = path.split("/", 2)[2]
    return path

def _typst_document_impl(ctx):
    typst = ctx.toolchains["//typst:toolchain_type"].typst
    name = ctx.label.name

    # The project root: every file at its path in the repository, sources
    # and generated files alike, because Typst reads from one tree only.
    staged = []
    for file in [ctx.file.main] + ctx.files.srcs:
        link = ctx.actions.declare_file("{}.root/{}".format(name, _root_path(ctx, file)))
        ctx.actions.symlink(output = link, target_file = file)
        staged.append(link)
    main = _root_path(ctx, ctx.file.main)
    root = staged[0].path.removesuffix("/" + main)

    # Typst refuses a main file that is a symlink out of the root, and
    # Bazel hands an action nothing but symlinks. So the main file is this
    # stub, on standard input.
    stub = ctx.actions.declare_file(name + ".stub.typ")
    ctx.actions.write(stub, '#include "/{}"\n'.format(main))

    pdf = ctx.actions.declare_file(name + ".pdf")
    args = ctx.actions.args()
    args.add_all([typst, stub])
    args.add("compile")
    args.add("--root", root)
    args.add("--ignore-system-fonts")
    args.add("--creation-timestamp", "0")

    # Neither directory exists, so no package is found, on the host or here.
    args.add("--package-path", root + ".packages")
    args.add("--package-cache-path", root + ".packages")
    args.add("-")
    args.add(pdf)
    ctx.actions.run_shell(
        command = 'typst="$1"; stub="$2"; shift 2; exec "$typst" "$@" < "$stub"',
        arguments = [args],
        inputs = staged + [stub],
        tools = [typst],
        outputs = [pdf],
        mnemonic = "TypstCompile",
        progress_message = "Compiling %{label}",
        toolchain = "//typst:toolchain_type",
        # A package that is not there is an error, not a download: the
        # sandbox has no network, and outside one this proxy is nobody.
        execution_requirements = {"block-network": "1"},
        env = {"ALL_PROXY": "http://127.0.0.1:1"},
    )
    return [DefaultInfo(files = depset([pdf]))]

typst_document = rule(
    implementation = _typst_document_impl,
    doc = "Compiles a Typst document to <name>.pdf.",
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
    },
    toolchains = ["//typst:toolchain_type"],
)
