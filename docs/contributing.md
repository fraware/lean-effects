# Contributing

Full notes live in the repository: **[CONTRIBUTING.md](https://github.com/fraware/lean-effects/blob/main/CONTRIBUTING.md)**.

Summary:

- Use the repo `lean-toolchain` and run `lake update` after dependency changes; commit `lake-manifest.json` when it changes.
- Before opening a PR: `lake build`, and `lake build Tests` to recheck everything under `tests/`.
- Optional: `lake exe test-suite`.
- For releases, bump [`VERSION`](https://github.com/fraware/lean-effects/blob/main/VERSION) to match your tag.

Automated checks run on [GitHub Actions](https://github.com/fraware/lean-effects/actions).
