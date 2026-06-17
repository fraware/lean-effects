# lean-effects documentation

**lean-effects** is a Lean 4 library for algebraic effects: theories, free monads, handlers, and supporting tactics. Start Lean files with `import Effects`.

## Toolchain

Lean and Mathlib are locked to versions that work together:

- [`lean-toolchain`](https://github.com/fraware/lean-effects/blob/main/lean-toolchain) — `leanprover/lean4:v4.31.0-rc1`
- Mathlib in [`lakefile.lean`](https://github.com/fraware/lean-effects/blob/main/lakefile.lean) — `v4.31.0-rc1`

[elan](https://github.com/leanprover/elan) is the usual way to match those versions locally.

## Module layout

| Layer | Import | Contents |
|-------|--------|----------|
| Stable core | `import Effects` | Core, Std, Compose (no DSL or tactics) |
| DSL | `import Effects.DSL` | `theory`, `derive_effect`, elaboration |
| Automation | `import Effects.Automation` | `effect_fuse!`, `handler_laws!`, `local_simp!` |

See [Extraction ledger](https://github.com/fraware/lean-effects/blob/main/docs/EXTRACTION_LEDGER.md) for CSLib extraction scope and remaining proof debt (one `sorry` in Nondet, one `mapConst` axiom).

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

- `lake build Effects` — stable library (Core, Std, Compose).
- `lake build Tests` — all modules in [`tests/`](https://github.com/fraware/lean-effects/tree/main/tests) (entry: [`tests/Tests.lean`](https://github.com/fraware/lean-effects/blob/main/tests/Tests.lean)).
- `lake build` — full default targets including benchmarks, CLI, and scripts.
- `lake exe test-suite` — optional extra checks (requires native linker).
- `lake exe Bench` — benchmarks.

Linux CI builds and tests the library on every push. Executable targets need a C compiler; on Windows set `LEAN_CC` if `cc` is not available.

Documentation site: install [`requirements.txt`](https://github.com/fraware/lean-effects/blob/main/docs/requirements.txt), then from `docs/` run `mkdocs build` or `mkdocs serve`.

See [CONTRIBUTING.md](https://github.com/fraware/lean-effects/blob/main/CONTRIBUTING.md) for versioning, telemetry, and Docker.

## Editing these docs

Add new `.md` files under `docs/pages/` and list them in [`mkdocs.yml`](https://github.com/fraware/lean-effects/blob/main/docs/mkdocs.yml).
