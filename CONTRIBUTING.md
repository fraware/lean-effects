# Contributing to lean-effects

## Toolchain

Lean and Mathlib versions are fixed together:

- [`lean-toolchain`](lean-toolchain) — version elan should use for this repo.
- [`Lakefile.lean`](Lakefile.lean) — Mathlib dependency at a matching tag.

If you change either, run `lake update` and commit the updated [`lake-manifest.json`](lake-manifest.json).

## Build and test

```bash
lake build
```

That builds the main library, tests under [`tests/`](tests) (via the `Tests` target), benchmarks, the command-line tool, and helper programs in [`scripts/`](scripts).

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

## Standards

- Do not add `sorry` in [`src/`](src/). Continuous integration rejects new uses under `src/`.
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

Sources are in [`docs/`](docs). The table of contents is [`docs/mkdocs.yml`](docs/mkdocs.yml): every listed page must exist or `mkdocs build` errors.

```bash
pip install -r docs/requirements.txt
cd docs && mkdocs serve
```

To link from the site to files only at the repo root (like this file), use a normal GitHub link to `blob/main/...`.
