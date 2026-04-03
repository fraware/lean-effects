# DSL Reference

!!! tip "Details in code"
    The running implementation is under [`src/Effects/DSL/`](https://github.com/fraware/lean-effects/tree/main/src/Effects/DSL), especially [`Syntax.lean`](https://github.com/fraware/lean-effects/blob/main/src/Effects/DSL/Syntax.lean) and [`Elab.lean`](https://github.com/fraware/lean-effects/blob/main/src/Effects/DSL/Elab.lean). This page is a summary; when in doubt, check those files.

This document summarizes the lean-effects DSL syntax and semantics.

## Theory Definition

### Basic Syntax

```lean
theory TheoryName (params : Type*) where
  op operation_name : InputType ⟶ OutputType
  eq equation_name : equation_expression
end
```

### Parameters

Theories can have type parameters:

```lean
theory State (σ : Type u) where
  op get : Unit ⟶ σ
  op put : σ ⟶ Unit
end
```

### Operations

Operations define the interface of an effect:

```lean
-- No parameters
op get : Unit ⟶ σ

-- Single parameter
op put : σ ⟶ Unit

-- Multiple parameters (using products)
op update : (σ × (σ → σ)) ⟶ Unit

-- Sum types for alternatives
op choose : (α ⊕ β) ⟶ α
```

### Equations

Equations define the laws that operations must satisfy:

```lean
theory State (σ : Type u) where
  op get : Unit ⟶ σ
  op put : σ ⟶ Unit
  
  -- Basic laws
  eq put_get : ∀ s, get (put s ()) = s
  eq get_put : ∀ s, put (get ()) s = s
  eq put_put : ∀ s₁ s₂, put s₂ (put s₁ ()) = put s₂ ()
end
```

## Code Generation

### derive_effect Command

```lean
derive_effect TheoryName [options...]
```

#### Options

- `free` - Generate free monad
- `handler` - Generate handler interface
- `fusion` - Generate fusion theorems
- `simp` - Generate simp packs

#### Example

```lean
derive_effect State [free, handler, fusion, simp]
```

### Generated Components

#### Free Monad

```lean
-- Generated type
inductive State.Free (α : Type u) where
  | pure : α → State.Free α
  | op : State.Op → (State.Result → State.Free α) → State.Free α

-- Monad instance
instance : Monad State.Free where
  pure := State.Free.pure
  bind := State.Free.bind
```

#### Handler Interface

```lean
-- Handler typeclass
class State.Handler (M : Type u → Type v) where
  handle : State.Op → M State.Result

-- Generic handler
def State.handle [State.Handler M] : State.Free α → M α
```

#### Catamorphism

```lean
-- Fold function
def State.fold [Monad M] (h : State.Handler M) : State.Free α → M α

-- Fusion theorem
theorem State.fusion [Monad M] [Monad N] 
  (h₁ : State.Handler M) (h₂ : M.Handler N) :
  State.fold h₂ ∘ State.fold h₁ = State.fold (h₁.compose h₂)
```

## Type System

### Allowed Types

In operation signatures, you can use:

- `Unit` - Unit type
- Type parameters - `α`, `β`, etc.
- Products - `α × β`
- Sums - `α ⊕ β`
- Functions - `α → β`

### Type Constraints

```lean
-- With constraints
theory MonoidWriter (ω : Type u) [Monoid ω] where
  op tell : ω ⟶ Unit
  eq tell_assoc : ∀ w₁ w₂, tell (w₁ * w₂) = tell w₁ >> tell w₂
end
```

## Standard Library

### State Effect

```lean
theory State (σ : Type u) where
  op get : Unit ⟶ σ
  op put : σ ⟶ Unit
  eq put_get : ∀ s, get (put s ()) = s
  eq get_put : ∀ s, put (get ()) s = s
  eq put_put : ∀ s₁ s₂, put s₂ (put s₁ ()) = put s₂ ()
end
```

### Reader Effect

```lean
theory Reader (ρ : Type u) where
  op ask : Unit ⟶ ρ
  eq ask_pure : ask () >>= pure = ask ()
end
```

### Writer Effect

```lean
theory Writer (ω : Type u) [Monoid ω] where
  op tell : ω ⟶ Unit
  eq tell_assoc : ∀ w₁ w₂, tell (w₁ * w₂) = tell w₁ >> tell w₂
  eq tell_empty : tell 1 = pure ()
end
```

### Exception Effect

```lean
theory Exception (ε : Type u) where
  op throw : ε ⟶ α
  eq throw_bind : ∀ e f, throw e >>= f = throw e
end
```

### Nondet Effect

```lean
theory Nondet where
  op empty : Unit ⟶ α
  op choice : (α ⊕ α) ⟶ α
  eq choice_assoc : ∀ x y z, choice (choice (x ⊕ y) ⊕ z) = choice (x ⊕ choice (y ⊕ z))
  eq choice_comm : ∀ x y, choice (x ⊕ y) = choice (y ⊕ x)
  eq choice_idem : ∀ x, choice (x ⊕ x) = x
end
```

## Composition

### Sum Theory

```lean
def SumTheory (T₁ : Theory) (T₂ : Theory) : Theory where
  op := T₁.Op ⊕ T₂.Op
  -- ... implementation details
```

### Product Theory

```lean
def ProdTheory (T₁ : Theory) (T₂ : Theory) : Theory where
  op := T₁.Op × T₂.Op
  -- ... implementation details
```

## Tactics

### effect_fuse!

Proves fusion theorems automatically:

```lean
theorem my_fusion : 
  State.fold h₂ ∘ State.fold h₁ = State.fold (h₁.compose h₂) := by
  effect_fuse!
```

### handler_laws!

Proves handler law obligations:

```lean
instance : State.Handler MyMonad where
  handle op := -- implementation
  -- Laws are proven automatically
  handler_laws!
```

## Implementation details

Codegen options, tracing flags, and timeouts are defined alongside the elaborator in [`Effects.DSL.Elab`](https://github.com/fraware/lean-effects/blob/main/src/Effects/DSL/Elab.lean). There is no separate stable `set_option` surface documented here; inspect that module (or use `#help option` in a scratch file) for what your build exposes.

## Best Practices

### Theory Design

1. **Keep operations simple** - Each operation should have a single responsibility
2. **Define meaningful equations** - Equations should capture the essential laws
3. **Use appropriate types** - Choose types that make the interface clear
4. **Consider composition** - Design for easy combination with other effects

### Handler Implementation

1. **Implement all operations** - Every operation must have a handler
2. **Preserve laws** - Handlers should satisfy the theory equations
3. **Use fusion** - Compose handlers efficiently using fusion theorems
4. **Test thoroughly** - Verify handlers work correctly in all cases

### Performance

1. **Use simp packs** - Enable automatic optimization
2. **Avoid deep nesting** - Keep effect composition shallow when possible
3. **Profile regularly** - Monitor performance with benchmarks
4. **Use fusion** - Compose handlers efficiently