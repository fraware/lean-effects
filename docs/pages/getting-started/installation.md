# Installation

## Prerequisites

- **Git**
- **[elan](https://github.com/leanprover/elan)** (recommended) so Lean matches [`lean-toolchain`](https://github.com/fraware/lean-effects/blob/main/lean-toolchain) (`v4.31.0-rc1`)
- **Python 3** (only to build the documentation site)
- **C compiler** (only for executables: `lake exe lean-effects`, `lake exe test-suite`)

The Lean version is the one named in `lean-toolchain`, with Mathlib at a compatible tag in [`lakefile.lean`](https://github.com/fraware/lean-effects/blob/main/lakefile.lean) (`v4.31.0-rc1`).

## Clone and build

```bash
git clone https://github.com/fraware/lean-effects.git
cd lean-effects
lake update
lake build Effects
lake build Tests
```

`lake build` compiles all default targets: library, tests, benchmarks, the `lean-effects` program, and Lean scripts registered in the Lake file.

## Check tests

```bash
lake build Tests
lake exe test-suite
```

## Use as a dependency

In your `lakefile.lean`:

```lean
require lean-effects from git
  "https://github.com/fraware/lean-effects.git" @ "main"
```

Pin a branch, tag, or commit that suits your project. Then:

```lean
import Effects              -- core + std + compose
import Effects.DSL          -- optional: custom theories
import Effects.Automation   -- optional: tactics
```

## Documentation site (local)

```bash
pip install -r docs/requirements.txt
cd docs
mkdocs serve
```

## Troubleshooting

### Downloads during `lake update`

Some steps fetch files from GitHub. If that fails (corporate network, Docker, and so on), try passing a GitHub token as described in [CONTRIBUTING.md](https://github.com/fraware/lean-effects/blob/main/CONTRIBUTING.md) and in the `Dockerfile` `GITHUB_TOKEN` build argument.

### Native link / `cc` not found (Windows)

Library builds (`lake build Effects`, `lake build Tests`) do not need a separate C compiler. Executables do. Set `LEAN_CC` to an installed compiler before running `lake exe …`, for example:

```powershell
$env:LEAN_CC = "clang"
lake exe test-suite
```

### TLS / certificates

Do not turn off HTTPS verification as a routine fix. Adjust trust store or proxy settings instead.

## See also

- [CONTRIBUTING.md](https://github.com/fraware/lean-effects/blob/main/CONTRIBUTING.md)
- [Extraction ledger](https://github.com/fraware/lean-effects/blob/main/docs/EXTRACTION_LEDGER.md)
