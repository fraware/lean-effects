# Core API (overview)

Overview of the main types and where they live. Open the linked `.lean` files for full definitions and lemmas.

## Module graph

| Area | Lean module | In `import Effects`? | Role |
|------|-------------|----------------------|------|
| Free monad | [`Effects.Core.Free`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Core/Free.lean) | Yes | `FreeMonad F` for a functor signature `F` |
| Handlers | [`Effects.Core.Handler`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Core/Handler.lean) | Yes | `Handler F M` + `buildHandler`, `interpret` |
| Fusion | [`Effects.Core.Fusion`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Core/Fusion.lean) | Yes | Fusion-style lemmas for handlers |
| Signatures | [`Effects.Core.SigUtil`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Core/SigUtil.lean) | Yes | `mapConst` axiom for indexed ops |
| Std effects | [`Effects.Std`](https://github.com/fraware/lean-effects/tree/main/src/Effects/Std) | Yes | State, Reader, Writer, Exception, Nondet |
| Composition | [`Effects.Compose`](https://github.com/fraware/lean-effects/tree/main/src/Effects/Compose) | Yes | Sum and product of signatures |
| DSL | [`Effects.DSL`](https://github.com/fraware/lean-effects/tree/main/src/Effects/DSL) | No (`import Effects.DSL`) | `theory`, `derive_effect`, etc. |
| Tactics | [`Effects.Automation`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Automation.lean) | No (`import Effects.Automation`) | `effect_fuse!`, `handler_laws!` |
| Aggregate import | [`Effects`](https://github.com/fraware/lean-effects/blob/main/src/Effects.lean) | — | Stable re-exports (Core + Std + Compose) |

## Free monad

The free monad is `Effects.Core.FreeMonad`:

```lean
inductive FreeMonad (F : Type u → Type u) (α : Type u) where
  | pure : α → FreeMonad F α
  | impure : F X → (X → FreeMonad F α) → FreeMonad F α
```

`bind`, `Monad`/`Functor` instances, and structural lemmas (`pure_bind`, `bind_pure`, `bind_assoc`) are defined in the same file.

## Handlers

Handlers interpret `FreeMonad F` into a monad `M`:

```lean
class Handler (F : Type u → Type u) (M : Type u → Type u) [Functor F] [Monad M] where
  interpret : FreeMonad F α → M α
  interpret_pure : ∀ x, interpret (pure x) = pure x
  interpret_bind : ∀ m f, interpret (bind m f) = bind (interpret m) (fun x => interpret (f x))
```

`Effects.Core.buildHandler` constructs a handler from an operation algebra `F α → M α`.

## Standard effects (implemented)

State, Reader, Writer, Exception, and Nondet live under [`Effects.Std`](https://github.com/fraware/lean-effects/tree/main/src/Effects/Std):

- [`State.lean`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Std/State.lean)
- [`Reader.lean`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Std/Reader.lean)
- [`Writer.lean`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Std/Writer.lean)
- [`Exception.lean`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Std/Exception.lean)
- [`Nondet.lean`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Std/Nondet.lean) — one tracked `sorry` in `NondetT.runFree_bind` (choice case)

Combining effects: [`Effects.Compose.Sum`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Compose/Sum.lean) and [`Effects.Compose.Product`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Compose/Product.lean).

## Tactics

Tactics live under [`Effects.Tactics`](https://github.com/fraware/lean-effects/tree/main/src/Effects/Tactics) and are re-exported by [`Effects.Automation`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Automation.lean). Use `import Effects.Automation` (not `import Effects` alone).

## Telemetry

[`Effects.Telemetry`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Telemetry.lean) is off unless you set `EFFECTS_TELEMETRY=true` ([CONTRIBUTING.md](https://github.com/fraware/lean-effects/blob/main/CONTRIBUTING.md)).

## Further reading

- [DSL reference](../reference/dsl-reference.md) — user-facing syntax summary  
- [Common patterns](../cookbook/common-patterns.md) — recipes and idioms  
- [Extraction ledger](https://github.com/fraware/lean-effects/blob/main/docs/EXTRACTION_LEDGER.md) — CSLib scope and proof debt  
- [Examples directory](https://github.com/fraware/lean-effects/tree/main/examples) — small runnable Lean files
