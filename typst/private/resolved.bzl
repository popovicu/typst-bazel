"""The Typst that toolchain resolution picks, as something to run."""

def _resolved_typst_impl(ctx):
    typst = ctx.toolchains["//typst:toolchain_type"].typst
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(output = executable, target_file = typst, is_executable = True)
    return [DefaultInfo(executable = executable)]

resolved_typst = rule(
    implementation = _resolved_typst_impl,
    executable = True,
    toolchains = ["//typst:toolchain_type"],
)

def _unchosen_typst_impl(ctx):
    fail("No Typst version is chosen. Add typst.toolchain(version = ...) to MODULE.bazel.")

unchosen_typst = rule(
    implementation = _unchosen_typst_impl,
    doc = "The toolchain when no module chose a version. It fails, but " +
          "only for a build that compiles a document.",
)
