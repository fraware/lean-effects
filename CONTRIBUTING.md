# Contributing to lean-effects

## Toolchain

Lean and Mathlib versions are fixed together:

- [`lean-toolchain`](lean-toolchain) — version elan should use for this repo (`v4.31.0`).
- [`lakefile.lean`](lakefile.lean) — Mathlib dependency at a matching tag (`v4.31.0`).

If you change either, run `lake update` and commit the updated [`lake-manifest.json`](lake-manifest.json).

## Module imports

| Goal | Import |
|------|--------|
| Core + standard effects + composition | `import Effects` |
| DSL (`theory`, `derive_effect`) | `import Effects.DSL` |
| Tactics (`effect_fuse!`, etc.) | `import Effects.Automation` |

`import Effects` does not load DSL elaboration or tactics.

## Build and test

```bash
lake build Effects
lake build Tests
```

Or `lake build` for the full default target set (library, tests, benchmarks, CLI, and scripts).

All test modules are pulled in through [`tests/Tests.lean`](tests/Tests.lean).

Optional executable checks:

```bash
lake exe test-suite
```

Other helpers:

```bash
lake exe performance-monitor
lake exe coverage-report
lake exe generate-docs
lake exe build-release
```

### Windows native link

Executables (`lake exe lean-effects`, `lake exe test-suite`) need a C compiler. On Windows, linking may fail when the default toolchain passes GNU-style linker flags to LLVM `clang` (for example `-no-pie`). Set `LEAN_CC` to an installed compiler before running `lake exe …`:

```powershell
$env:LEAN_CC = "clang"
lake exe test-suite
```

Library builds (`lake build Effects`, `lake build Tests`) do not require a separate C compiler. Continuous integration treats Windows executable checks as non-blocking; Linux CI runs them as part of the main build job.

## Standards

- **CSLib candidate modules** must not contain `sorry`. The list is enforced by [`scripts/check-no-sorry.sh`](scripts/check-no-sorry.sh):
  - `Effects.Core.Free`, `Effects.Core.Handler`
  - `Effects.Std.State`, `Effects.Std.Exception`, `Effects.Std.Reader`, `Effects.Std.Writer`
  - `Effects.Compose.Sum`, `Effects.Compose.Product`
- Do not add `sorry` in [`src/`](src/). Continuous integration rejects any `sorry` under `src/`.
- The `mapConst` axiom in [`Effects.Core.SigUtil`](src/Effects/Core/SigUtil.lean) is intentional for indexed signatures; document any change in [`docs/EXTRACTION_LEDGER.md`](docs/EXTRACTION_LEDGER.md).
- Prefer small Mathlib imports where you can. Document public APIs in source when behavior is not obvious.
- Follow existing naming, layout, and proof style in files you touch.

## Releases and versioning

- Update [`VERSION`](VERSION) when you cut a release; the CLI reads it from [`Main.lean`](Main.lean).
- Use a matching git tag (for example `v1.0.0` when `VERSION` is `1.0.0`).

## Telemetry

Off unless you opt in:

```bash
export EFFECTS_TELEMETRY=true
```

## Docker

If `lake update` fails when dependencies need to reach GitHub, build with a token:

```bash
docker build --build-arg GITHUB_TOKEN=$GITHUB_TOKEN -t lean-effects:local .
```

## Documentation site

Sources are in [`docs/`](docs). MkDocs pages live under [`docs/pages/`](docs/pages/); the table of contents is [`docs/mkdocs.yml`](docs/mkdocs.yml).

```bash
pip install -r docs/requirements.txt
cd docs && mkdocs serve
```

To link from the site to files only at the repo root (like this file), use a normal GitHub link to `blob/main/...`.
