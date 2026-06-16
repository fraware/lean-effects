# Extraction ledger

Tracks what is ready for CSLib upstream versus what remains repository-local during the modernization sprint.

## Ready for extraction

| Item | Location | Status |
|------|----------|--------|
| Free monad core | `Effects.Core.Free` | Candidate |
| Interpretation lemmas (`interpret_pure`, `interpret_bind`, fold) | `Effects.Core.Free`, `Effects.Core.Handler` | Candidate |
| Handler structure | `Effects.Core.Handler` | Candidate |
| Catamorphism fusion (basic) | `Effects.Core.Fusion` | Candidate |
| State example (`get` / `put` / `run`) | `Effects.Std.State` | Candidate |
| Exception example (`throw` / `catch` / `run`) | `Effects.Std.Exception` | Candidate |
| Reader example (`ask` / `local` / `run`) | `Effects.Std.Reader` | Candidate |
| Writer example (`tell` / `run`) | `Effects.Std.Writer` | Candidate |
| Sum / product composition | `Effects.Compose.Sum`, `Effects.Compose.Product` | Candidate |
| Nondet example (`empty` / `choice` / `run`) | `Effects.Std.Nondet` | Candidate (runtime; `NondetT.runFree_bind` choice case still `sorry`) |

## Postponed

| Item | Notes |
|------|-------|
| Lawvere theory layer | Mathematically important; upstream after free-monad and handler core |
| DSL extraction | `Effects.DSL` (syntax, elaboration, `derive_effect`) stays local |
| Tactics | `effect_fuse!`, `handler_laws!`, `local_simp!` not upstreamed this sprint; macro-based stubs build on 4.31 |
| Scripts | Performance monitor, coverage, release builder, doc generator |
| `interpret_bind` gaps | Proven: State, Reader, Writer, Exception, Sum, Product. `sorry`: Nondet `choice` in `NondetT.runFree_bind` (target lemma: `append_concatMap_runFree` via `mapM_flatten_append_bind` + mutual prefix/concat lemmas) |
| `mapConst` axiom | Required for indexed signatures (State/Reader/Writer): `Functor.map` cannot be defined when operation indices vary (`get : StateSig σ σ`, `put : StateSig σ PUnit`, etc.). Axiom lives in `Effects.Core.SigUtil`. |
| Combo integration tests | `tests/Tests/Combo/*` exist but are not wired into the `Tests` aggregator yet |

## Upstream PR order

1. CSLib design issue or draft PR: minimal free monad API (`Free`, `pure`, `bind`, `map`, `fold`/`interpret`, simp lemmas).
2. CSLib PR: interpretation lemmas (`interpret_pure`, `interpret_bind`, handler laws).
3. CSLib PR: State and Exception executable examples.
4. CSLib PR: Reader, Writer, Nondet, and composition (Sum/Product) examples.
5. Later discussion: Lawvere theory skeleton.
6. Much later: DSL and tactics.

## Stable import surface

```lean
import Effects              -- core + std + compose only
import Effects.Core         -- free monad, handler, fusion
import Effects.Std          -- standard effects
import Effects.Compose      -- sum and product
import Effects.DSL          -- optional: theories and elaboration
import Effects.Automation   -- optional: tactics
```

`import Effects` does not load DSL elaboration or tactics.

## Build notes (Lean 4.31)

- Libraries: `lake build Effects` and `lake build Tests` succeed on 4.31.0-rc1 with mathlib `v4.31.0-rc1`.
- Executables (`lake exe lean-effects`, `lake exe test-suite`) require a C toolchain; on Windows set `LEAN_CC` to `clang` (or another installed compiler) if `cc` is not on `PATH`.
