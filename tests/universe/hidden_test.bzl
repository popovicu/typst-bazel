"""Tests that a package nobody asked for cannot be named."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _hidden_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "is not visible from")
    return analysistest.end(env)

hidden_test = analysistest.make(_hidden_test_impl, expect_failure = True)
