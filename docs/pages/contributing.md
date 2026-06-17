# Contributing

Full notes live in the repository: **[CONTRIBUTING.md](https://github.com/fraware/lean-effects/blob/main/CONTRIBUTING.md)**.

Summary:

- Toolchain: Lean `v4.31.0-rc1`, Mathlib `v4.31.0-rc1` (`lean-toolchain`, `lakefile.lean`). Run `lake update` after dependency changes; commit `lake-manifest.json` when it changes.
- Stable import: `import Effects` (Core + Std + Compose). Add `Effects.DSL` and `Effects.Automation` when you need the DSL or tactics.
- Before opening a PR: `lake build Effects`, `lake build Tests`.
- Optional: `lake exe test-suite` (needs native linker; on Windows set `LEAN_CC` if `cc` is missing).
- Do not add `sorry` in `src/` except the tracked Nondet gap. See [Extraction ledger](https://github.com/fraware/lean-effects/blob/main/docs/EXTRACTION_LEDGER.md).
- For releases, bump [`VERSION`](https://github.com/fraware/lean-effects/blob/main/VERSION) to match your tag.

Automated checks run on [GitHub Actions](https://github.com/fraware/lean-effects/actions) (Linux).
