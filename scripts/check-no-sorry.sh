#!/usr/bin/env bash
# Fail if any CSLib candidate module contains `sorry`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CSLIB_MODULES=(
  "src/Effects/Core/Free.lean"
  "src/Effects/Core/Handler.lean"
  "src/Effects/Std/State.lean"
  "src/Effects/Std/Exception.lean"
  "src/Effects/Std/Reader.lean"
  "src/Effects/Std/Writer.lean"
  "src/Effects/Std/Nondet.lean"
  "src/Effects/Compose/Sum.lean"
  "src/Effects/Compose/Product.lean"
)

failed=0
for rel in "${CSLIB_MODULES[@]}"; do
  path="${ROOT}/${rel}"
  if [[ ! -f "${path}" ]]; then
    echo "::error::Missing CSLib module file: ${rel}"
    failed=1
    continue
  fi
  if grep -nE '\bsorry\b' "${path}"; then
    echo "::error::Found sorry in CSLib candidate module: ${rel}"
    failed=1
  fi
done

if [[ "${failed}" -ne 0 ]]; then
  exit 1
fi

echo "No sorry in CSLib candidate modules."
