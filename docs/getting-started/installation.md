# Installation

## Prerequisites

- Lean 4.8.0 or later
- Lake package manager
- Git

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/fraware/lean-effects.git
   cd lean-effects
   ```

2. **Install dependencies:**
   ```bash
   lake update
   ```

3. **Build the project:**
   ```bash
   lake build
   ```

4. **Run tests:**
   ```bash
   lake test
   ```

## Using as a Dependency

Add to your `lakefile.lean`:

```lean
require lean-effects from git
  "https://github.com/fraware/lean-effects.git" @ "main"
```

## Troubleshooting

### Certificate Issues

If you encounter certificate verification errors during dependency installation:

```bash
git config --global http.sslVerify false
export CURL_INSECURE=1
export GIT_SSL_NO_VERIFY=true
lake update
```

### ProofWidgets Issues

If ProofWidgets fails to download, this is a known issue with certificate revocation checks. The CI/CD pipeline handles this automatically, but for local development, you may need to work around this issue.

## Development Setup

For contributing to lean-effects:

1. Fork the repository
2. Clone your fork
3. Install development dependencies:
   ```bash
   lake update
   pip install -r docs/requirements.txt
   ```
4. Build and test:
   ```bash
   lake build
   lake test
   ```