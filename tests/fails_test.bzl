"""A test that a target cannot be analyzed, and says why."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _fails_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, ctx.attr.message)
    return analysistest.end(env)

fails_test = analysistest.make(
    _fails_test_impl,
    expect_failure = True,
    attrs = {"message": attr.string(mandatory = True)},
)
