# Basic Usage

## Introduction

lean-effects provides a DSL for defining algebraic effects and their handlers. This guide covers the basic concepts and usage patterns.

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
import Effects.Std

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

```lean
import Effects.Std

-- State with type parameter
def myProgram : State.Free Nat String := do
  let current ← State.get
  State.put (current + 1)
  return s!"Count is {current}"
```

### Reader Effect

```lean
-- Reader with environment type
def myReaderProgram : Reader.Free String Int := do
  let env ← Reader.ask
  return env.length
```

### Writer Effect

```lean
-- Writer with monoid
def myWriterProgram : Writer.Free (List String) Unit := do
  Writer.tell ["Starting computation"]
  Writer.tell ["Processing data"]
  Writer.tell ["Finished"]
```

### Exception Effect

```lean
-- Exception handling
def myExceptionProgram : Exception.Free String Int := do
  let result ← Exception.throw "Something went wrong"
  return result
```

## Composition

### Sum of Effects

```lean
def StateWithException := SumTheory State Exception

def combinedProgram : StateWithException.Free Nat String := do
  let current ← State.get
  if current > 10 then
    Exception.throw "Too large"
  else
    State.put (current + 1)
    return "OK"
```

### Product of Effects

```lean
def ReaderWithWriter := ProdTheory Reader Writer

def loggedReaderProgram : ReaderWithWriter.Free String Int := do
  let env ← Reader.ask
  Writer.tell ["Processing environment"]
  return env.length
```

## Next Steps

- [First Example](first-example.md) - A complete working example
- [DSL Reference](reference/dsl-reference.md) - Complete syntax reference
- [Common Patterns](cookbook/common-patterns.md) - Real-world usage patterns