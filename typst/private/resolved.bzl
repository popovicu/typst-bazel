"""The Typst that toolchain resolution picks, as something to run."""

def _resolved_typst_impl(ctx):
    typst = ctx.toolchains["//typst:toolchain_type"].typst
    suffix = ".exe" if typst.extension == "exe" else ""
    executable = ctx.actions.declare_file(ctx.label.name + suffix)
    ctx.actions.symlink(output = executable, target_file = typst, is_executable = True)
    return [DefaultInfo(executable = executable)]

resolved_typst = rule(
    implementation = _resolved_typst_impl,
    executable = True,
    toolchains = ["//typst:toolchain_type"],
)
