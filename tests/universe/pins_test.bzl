"""Tests of reading a lock file."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//typst/private:pins.bzl", "read_pins")

_PIN = '"oxifmt:1.0.0": {"deps": [], "sha256": "7d17"}'

def _pins_test(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, {}, read_pins("{}\n"))
    asserts.equals(
        env,
        {"oxifmt:1.0.0": {"deps": [], "sha256": "7d17"}},
        read_pins("{" + _PIN + "}"),
    )

    # Nothing, half a merge, another shape, and entries that lack a part.
    for damaged in [
        "",
        "<<<<<<< HEAD\n{" + _PIN + "}\n=======\n{}\n>>>>>>> theirs\n",
        "[]",
        '{"oxifmt:1.0.0": "7d17"}',
        '{"oxifmt:1.0.0": {"sha256": "7d17"}}',
        '{"oxifmt:1.0.0": {"deps": []}}',
    ]:
        asserts.equals(env, None, read_pins(damaged))
    return unittest.end(env)

pins_test = unittest.make(_pins_test)
