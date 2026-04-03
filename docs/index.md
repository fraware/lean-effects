# lean-effects documentation

**lean-effects** is a Lean 4 library for algebraic effects: theories, free monads, handlers, and supporting tactics. Start Lean files with `import Effects`.

## Toolchain

Lean and Mathlib are locked to versions that work together:

- [`lean-toolchain`](https://github.com/fraware/lean-effects/blob/main/lean-toolchain)
- Mathlib in [`Lakefile.lean`](https://github.com/fraware/lean-effects/blob/main/Lakefile.lean)

[elan](https://github.com/leanprover/elan) is the usual way to match those versions locally.

## Quick start

1. [Installation](getting-started/installation.md)
2. [Basic usage](getting-started/basic-usage.md)
3. [First example](getting-started/first-example.md)

## Pages in this site

| Topic | Page |
|-------|------|
| DSL | [DSL reference](reference/dsl-reference.md) |
| Core types | [Core API](api/core.md) |
| Patterns | [Common patterns](cookbook/common-patterns.md) |

The library source is under [`src/Effects/`](https://github.com/fraware/lean-effects/tree/main/src/Effects).

## Building and testing

- `lake build` — main library, tests, benchmarks, CLI, and scripts.
- `lake build Tests` — all modules in [`tests/`](https://github.com/fraware/lean-effects/tree/main/tests) (entry: [`tests/Tests.lean`](https://github.com/fraware/lean-effects/blob/main/tests/Tests.lean)).
- `lake exe test-suite` — optional extra checks.
- `lake exe Bench` — benchmarks.

Documentation site: install [`requirements.txt`](https://github.com/fraware/lean-effects/blob/main/docs/requirements.txt), then from `docs/` run `mkdocs build` or `mkdocs serve`.

See [CONTRIBUTING.md](https://github.com/fraware/lean-effects/blob/main/CONTRIBUTING.md) for versioning, telemetry, and Docker.

## Editing these docs

Add new `.md` files under `docs/` and list them in [`mkdocs.yml`](https://github.com/fraware/lean-effects/blob/main/docs/mkdocs.yml).
