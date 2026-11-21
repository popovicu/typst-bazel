"""The rule that makes a Typst binary a toolchain."""

def _typst_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        typst = ctx.executable.typst,
        version = ctx.attr.version,
    )]

typst_toolchain = rule(
    implementation = _typst_toolchain_impl,
    doc = "A Typst compiler. Wrap one in toolchain() to offer it to builds.",
    attrs = {
        "typst": attr.label(
            doc = "The typst executable.",
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "version": attr.string(
            doc = "The version of that executable, as in 0.15.1.",
            mandatory = True,
        ),
    },
)
