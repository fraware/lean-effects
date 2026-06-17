# Documentation source

MkDocs project root: [`mkdocs.yml`](mkdocs.yml) sets `docs_dir: pages` and `site_dir: _site`.

- Start page: [pages/index.md](pages/index.md)
- Build: `pip install -r requirements.txt`, then `mkdocs build` from this directory (output in `_site/`)
- On GitHub, the Documentation workflow runs Lean builds, doc helpers, then MkDocs

Add or rename pages under `pages/` and list them in `mkdocs.yml` navigation.

Repository-wide notes: [CONTRIBUTING.md](../CONTRIBUTING.md), [README.md](../README.md), [EXTRACTION_LEDGER.md](EXTRACTION_LEDGER.md).
