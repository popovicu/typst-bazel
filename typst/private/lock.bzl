"""Rules for the repository of packages, about its lock file."""

def _unlocked_package_impl(ctx):
    fail("{} does not pin {}. To pin what it lacks: bazel run @preview//:lock".format(
        ctx.attr.lock_file,
        ", ".join(["@preview/" + spec for spec in ctx.attr.unlocked]),
    ))

unlocked_package = rule(
    implementation = _unlocked_package_impl,
    doc = "Stands in for every package while the lock file lacks some.",
    attrs = {
        "lock_file": attr.string(),
        "unlocked": attr.string_list(),
    },
)

_WRITE = """\
#!/bin/sh
set -eu
cat > "$BUILD_WORKSPACE_DIRECTORY/{lock_file}" <<'END_OF_LOCK'
{lock}END_OF_LOCK
echo "Wrote {lock_file}"
"""

def _write_lock_impl(ctx):
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        script,
        _WRITE.format(lock_file = ctx.attr.lock_file, lock = ctx.attr.lock),
        is_executable = True,
    )
    return [DefaultInfo(executable = script)]

write_lock = rule(
    implementation = _write_lock_impl,
    doc = "Writes the lock file into the workspace when run.",
    executable = True,
    attrs = {
        "lock_file": attr.string(doc = "Its path in the workspace."),
        "lock": attr.string(doc = "What it should say."),
    },
)
