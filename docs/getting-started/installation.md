# Installation

## Prerequisites

- **Git**
- **[elan](https://github.com/leanprover/elan)** (recommended) so Lean matches [`lean-toolchain`](https://github.com/fraware/lean-effects/blob/main/lean-toolchain)
- **Python 3** (only to build the documentation site)

The Lean version is the one named in `lean-toolchain`, with Mathlib at a compatible tag in `Lakefile.lean`.

## Clone and build

```bash
git clone https://github.com/fraware/lean-effects.git
cd lean-effects
lake update
lake build
```

`lake build` compiles the library, everything in `tests/`, benchmarks, the `lean-effects` program, and the Lean scripts registered in the Lake file.

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
import Effects
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

### TLS / certificates

Do not turn off HTTPS verification as a routine fix. Adjust trust store or proxy settings instead.

## See also

- [CONTRIBUTING.md](https://github.com/fraware/lean-effects/blob/main/CONTRIBUTING.md)
