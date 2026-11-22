# Working in this repo

typst-bazel is a set of Bazel rules for the Typst typesetting compiler.
Read `README.md` first.

## Commits

- One idea per commit. Build and tests are green at every commit.
- Keep hand-written changes small (aim for under ~150 changed lines;
  goldens and lockfiles don't count). If a change is bigger, split it.
  `tools/hooks/pre-commit` rejects anything over 200.
- Each commit should be reviewable on its own, in order, by someone reading
  the history commit by commit.
- Commit messages: one line, imperative mood, no trailers.
- Never push. Pushing is the user's call.

## Docs

- Docs describe the present. No history, no changelogs: git history is
  the log.
- When code changes, update the doc that describes it in the same commit,
  or delete the stale text.
- Allowed docs: `README.md` (what and how), `docs/rules.md` (every rule,
  attribute and provider), `DESIGN.md` (decisions and why, edited in
  place), `REVISIT.md` (provisional decisions to come back to), and
  `CLAUDE.md` (this file). Nothing else unless agreed.
- A rule or an attribute that changes is changed in `docs/rules.md` in
  the same commit.

## Structure

- `//typst` is the public surface: `defs.bzl` for rules, `extensions.bzl`
  for the module extension. Everything under `//typst/private` can change
  without notice.
- Rules decide everything at analysis time and run Typst itself as the
  action. There is no wrapper program between Bazel and Typst.
- `//tests` uses only the public surface, as another module would.
- `//examples` is what a user would write, and is tested like the rest.
  Nothing in it is about a real person.
- Every change comes with tests.

## Tooling

- `bazel build //...` and `bazel test //...` must pass before every commit.
- Bazel version is pinned in `.bazelversion`.
- Nothing is needed on the host besides Bazel and a shell: Typst, the
  packages documents import, and fonts all come through Bazel.
- After cloning, turn the commit-size hook on:
  `git config core.hooksPath tools/hooks`.

## The examples repository

`../typst-bazel-examples` uses these rules as another module would,
through a path override to this checkout. After a change to a rule or to
the extension, run `bazel test //...` there too. A problem it finds is
fixed here, not worked around there.

## Trying what the tests cannot reach

What the extension downloads, and how several modules combine, cannot be
tested from inside `//tests`. These are tried by hand:

- Another module: a scratch directory whose `MODULE.bazel` has a
  `local_path_override` to this checkout. `house/` in the examples
  repository is a module that is depended on and has packages.
- Packages Typst Universe does not have: make `name-1.0.0.tar.gz`
  archives with the files at the top, serve the directory with
  `python3 -m http.server`, and give Bazel a `--downloader_config` file
  saying `rewrite packages.typst.org/preview/(zz-.*)
  http://127.0.0.1:PORT/$1`, on one line.
- A download that fails: the same flag, rewriting to `127.0.0.1:1`.
- Outside the sandbox: `--spawn_strategy=local`.

Bazel keeps a failure of the module extension until its server
restarts, whatever changed outside the files it watches: run
`bazel shutdown` between tries.

## AI-written

This repository is written by AI, and `README.md` says so. Check what a
doc says against the code before relying on it, and fix whichever is
wrong.
