# Working in this repo

rules_typst is a set of Bazel rules for the Typst typesetting compiler.
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
- Allowed docs: `README.md` (what and how), `DESIGN.md` (decisions and
  why, edited in place), `REVISIT.md` (provisional decisions to come back
  to), and `CLAUDE.md` (this file). Nothing else unless agreed.

## Structure

- `//typst` is the public surface: `defs.bzl` for rules, `extensions.bzl`
  for the module extension. Everything under `//typst/private` can change
  without notice.
- Rules decide everything at analysis time and run Typst itself as the
  action. There is no wrapper program between Bazel and Typst.
- `//tests` uses only the public surface, as another module would.
- Every change comes with tests.

## Tooling

- `bazel build //...` and `bazel test //...` must pass before every commit.
- Bazel version is pinned in `.bazelversion`.
- Nothing is needed on the host besides Bazel and a shell: Typst, the
  packages documents import, and fonts all come through Bazel.
- After cloning, turn the commit-size hook on:
  `git config core.hooksPath tools/hooks`.
