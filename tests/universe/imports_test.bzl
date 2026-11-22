"""Tests of finding the packages a source imports."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//typst/private:imports.bzl", "preview_imports")
load("//typst/private:universe.bzl", "splits_package")

_SOURCE = """\
#import "@preview/cetz:0.5.3"
#import "@preview/oxifmt:1.0.0": strfmt
#import "@preview/cetz:0.5.3": draw
/// #import "@preview/in-a-doc-comment:1.0.0": *
  // "@preview/in-a-comment:1.0.0"
#let lazy() = {
  import "@preview/hy-dro-gen:0.1.1" as hy
}
#import "@local/elsewhere:1.0.0"
#import "@preview/no-version"
#import "@preview/short:1.0"
#import "@preview/not a name:1.0.0"
#include "@preview/two:2.0.0"; #import "@preview/on_a_line:10.20.30"
"""

def _imports_test(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, [
        "cetz:0.5.3",
        "oxifmt:1.0.0",
        "hy-dro-gen:0.1.1",
        "two:2.0.0",
        "on_a_line:10.20.30",
    ], preview_imports(_SOURCE))
    asserts.equals(env, [], preview_imports("= No imports\n"))
    return unittest.end(env)

imports_test = unittest.make(_imports_test)

def _splits_test(ctx):
    env = unittest.begin(ctx)
    for name in ["BUILD", "build", "BUILD.bazel", "Build.Bazel", "WORKSPACE", "MODULE.bazel", "REPO.bazel"]:
        asserts.true(env, splits_package(name), name)
    for name in ["build.typ", "builder", "lib.typ", "typst.toml", "BUILD.md"]:
        asserts.false(env, splits_package(name), name)
    return unittest.end(env)

splits_test = unittest.make(_splits_test)
