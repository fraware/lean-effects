# Modernization and extraction sprint

This document records the modernization and extraction plan for `lean-effects` as part of the broader category-theory contribution program targeting Mathlib and CSLib.

## Current repository position

`lean-effects` formalizes algebraic effects through Lawvere-theory-style descriptions, free monads, handlers, fusion, standard effects, effect composition, DSL support, and tactics.

This repository is strategically important for CSLib because it connects category-theoretic semantics to executable programming-language infrastructure. It should not be upstreamed as one large effects framework. The first extraction should be a minimal, well-lawed core that CSLib contributors can use and review.

Current toolchain (certified on branch `modernize/lean-4-31-extraction`):

- `lean-toolchain`: `leanprover/lean4:v4.31.0-rc1`
- `lakefile.lean`: Mathlib at `v4.31.0-rc1`
- `lake build Effects` and `lake build Tests` succeed on Linux CI
- Executables (`lake exe lean-effects`, `lake exe test-suite`) require a native C compiler; on Windows set `LEAN_CC` to `clang` (or another installed compiler) if `cc` is not on `PATH`

## Module layout

| Module | Path | In `import Effects`? | Role |
|--------|------|----------------------|------|
| Core | `Effects.Core.*` | Yes | Free monad, handlers, fusion, signature utilities |
| Std | `Effects.Std.*` | Yes | State, Reader, Writer, Exception, Nondet |
| Compose | `Effects.Compose.*` | Yes | Sum and product of effect signatures |
| DSL | `Effects.DSL.*` | No | `theory`, `derive_effect`, elaboration |
| Automation | `Effects.Automation` | No | `effect_fuse!`, `handler_laws!`, `local_simp!` |

Stable import surface:

```lean
import Effects              -- core + std + compose only
import Effects.DSL          -- optional: theories and elaboration
import Effects.Automation   -- optional: tactics
```

See [`EXTRACTION_LEDGER.md`](EXTRACTION_LEDGER.md) for CSLib in/out scope and remaining proof debt.

## Sprint objective

Port the repository to Lean 4.31 / Mathlib v4.31.0-rc1 and extract a small CSLib-facing core around free monads, handlers, and standard semantic examples.

The first upstream outputs should be definitions, law statements, and executable examples. DSL elaboration, tactics, and effect-fusion automation remain local until the core is stable.

## Modernization gates

### Gate 1: port to Lean 4.31 (done)

Required commands:

```bash
lake update
lake build Effects
lake build Tests
lake exe lean-effects --help   # needs native linker
lake exe test-suite            # needs native linker
```

Resolved during the sprint: moved Mathlib imports, monad notation, DSL elaborator drift, tactic macro stubs, Bench `Timeit` removal, lowercase `lakefile.lean` for Linux CI.

### Gate 2: split stable core from DSL and automation (done)

Layout:

```text
src/Effects/Core/Free.lean
src/Effects/Core/Handler.lean
src/Effects/Core/Fusion.lean
src/Effects/Core/SigUtil.lean
src/Effects/Std/*.lean
src/Effects/Compose/Sum.lean
src/Effects/Compose/Product.lean
src/Effects/DSL.lean
src/Effects/Automation.lean
src/Effects.lean                  -- stable public import
```

### Gate 3: define the CSLib extraction slice (in progress)

First CSLib candidate (pick one to lead):

1. minimal `FreeMonad` API with bind, pure, fold/interpret, and simp lemmas;
2. minimal handler API with correctness lemmas;
3. standard State and Exception executable examples.

Do not include the DSL in the first CSLib contribution.

## Remaining proof debt

| Item | Location | Notes |
|------|----------|-------|
| `NondetT.runFree_bind` choice case | `Effects.Std.Nondet` | One tracked `sorry`; CI allows only this file |
| `mapConst` axiom | `Effects.Core.SigUtil` | Required for indexed operation signatures (State/Reader/Writer) |

## Non-upstream material (unchanged)

- DSL syntax and elaboration
- `derive_effect` machinery
- `effect_fuse!`, `handler_laws!`, `local_simp!`
- performance monitor, coverage report, release builder, doc generator scripts
- broad fusion automation beyond the Core lemmas

## First PR candidates

1. Local modernization PR: port to Lean 4.31 and current Mathlib (merged on feature branch).
2. Local architecture PR: separate stable core from DSL, automation, and scripts (done).
3. CSLib candidate PR: minimal free monad with interpretation lemmas.
4. CSLib candidate PR: State and Exception examples over the minimal API.
5. Mathlib discussion candidate: Lawvere-theory design notes after the free-monad core is stable.
