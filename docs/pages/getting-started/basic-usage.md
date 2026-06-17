# Basic Usage

!!! note "Snippets"
    The `theory` / `derive_effect` examples are sketches. For code that matches this repo exactly, use [`examples/BasicExample.lean`](https://github.com/fraware/lean-effects/blob/main/examples/BasicExample.lean) (`import Effects.DSL` + `Effects.Automation`) or [`examples/StateExample.lean`](https://github.com/fraware/lean-effects/blob/main/examples/StateExample.lean) (stable `import Effects` only).

## Introduction

lean-effects provides a DSL for defining algebraic effects and their handlers. This guide covers basic concepts and usage patterns.

## Core Concepts

### Effect Theories

An effect theory defines the operations and equations for a particular effect:

```lean
theory State (σ : Type u) where
  op get  : Unit ⟶ σ
  op put  : σ    ⟶ Unit
  eq put_get : ∀ s, get (put s ()) = s
end
```

### Code Generation

Use the `derive_effect` command to generate the free monad and handlers:

```lean
derive_effect State [free, handler, fusion, simp]
```

This generates:
- `State.Free` - the free monad
- `State.handle` - generic handler interface
- `State.fold` - catamorphism with fusion theorems
- Simp packs for optimization

### Basic Example

```lean
import Effects

-- Define a simple state effect
theory Counter where
  op increment : Unit ⟶ Unit
  op get_count : Unit ⟶ Nat
end

derive_effect Counter [free, handler, fusion, simp]

-- Use the effect
def program : Counter.Free Unit := do
  Counter.increment ()
  Counter.increment ()
  Counter.get_count ()

-- Run with a handler
def runCounter (init : Nat) : Counter.Free α → α × Nat :=
  Counter.fold (init, fun (_, n) => ((), n + 1))
```

## Standard Library Effects

### State Effect

The shipped API uses explicit type arguments on operations (see [`Effects.Std.State`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Std/State.lean)):

```lean
import Effects

def myProgram : State.Free Nat String := do
  let current ← State.get Nat
  State.put Nat (current + 1)
  pure s!"Count is {current}"
```

### Reader Effect

```lean
import Effects

def myReaderProgram : Reader.Free Nat Nat := do
  let env ← Reader.ask Nat
  pure (env + 1)
```

### Writer Effect

Writer uses a monoid on the log type `ω` (for example `String` with concatenation):

```lean
import Effects

def myWriterProgram : Writer.Free String Unit := do
  Writer.tell String "Starting computation"
  Writer.tell String "Finished"
```

### Exception Effect

```lean
import Effects

def myExceptionProgram : Exception.Free String Nat :=
  Exception.throw String "Something went wrong"
```

## Composition

Sum and product constructions are in [`Effects.Compose.Sum`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Compose/Sum.lean) and [`Effects.Compose.Product`](https://github.com/fraware/lean-effects/blob/main/src/Effects/Compose/Product.lean). Generated client code for combined theories appears under [`tests/Combo/`](https://github.com/fraware/lean-effects/tree/main/tests/Combo) (for example `StateExceptionTest`, `ReaderWriterTest`). Prefer those modules over copying long snippets here, since types and namespaces track the DSL output closely.

## Next Steps

- [First Example](first-example.md) - A complete working example
- [DSL Reference](../reference/dsl-reference.md) - Complete syntax reference
- [Common Patterns](../cookbook/common-patterns.md) - Real-world usage patterns