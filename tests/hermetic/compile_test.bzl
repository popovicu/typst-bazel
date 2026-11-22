"""A test of how documents run Typst: what keeps the machine out."""

_CompileInfo = provider(
    doc = "The action that compiles a document.",
    fields = ["argv", "env"],
)

def _compile_aspect_impl(target, _ctx):
    for action in target.actions:
        if action.mnemonic == "TypstCompile":
            return [_CompileInfo(argv = action.argv, env = action.env)]
    fail("{} does not compile a document".format(target.label))

_compile_aspect = aspect(implementation = _compile_aspect_impl)

def _problems(label, compile):
    """What is missing of the things that keep the machine out."""
    wanted = {
        # Fonts of the machine.
        "--ignore-system-fonts": "--ignore-system-fonts" in compile.argv,
        # Packages the machine has, in either place Typst looks.
        "--package-path": "--package-path" in compile.argv,
        "--package-cache-path": "--package-cache-path" in compile.argv,
        # The clock.
        "--creation-timestamp": "--creation-timestamp" in compile.argv,
        # The network. That the sandbox blocks it too is not something a
        # rule can read of an action.
        "a proxy that is nobody": compile.env.get("ALL_PROXY") == "http://127.0.0.1:1",
    }
    return ["{} compiles without {}".format(label, what) for what, there in wanted.items() if not there]

def _compile_test_impl(ctx):
    problems = []
    for document in ctx.attr.documents:
        problems.extend(_problems(document.label, document[_CompileInfo]))
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        script,
        "#!/bin/sh\n" + "".join(["echo '{}' >&2\n".format(problem) for problem in problems]) +
        ("exit 1\n" if problems else "echo PASS\n"),
        is_executable = True,
    )
    return [DefaultInfo(executable = script)]

compile_test = rule(
    implementation = _compile_test_impl,
    doc = "Passes if each document's compile action keeps the machine out.",
    test = True,
    attrs = {"documents": attr.label_list(aspects = [_compile_aspect])},
)
