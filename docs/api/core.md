# Core API Reference

This document provides comprehensive API documentation for the core lean-effects library.

## Effects Module

### Main Effects Type

```lean
namespace Effects
  -- Core effect type
  inductive Effect (α : Type u) where
    | pure : α → Effect α
    | op : OperationType → Effect α
end
```

### Free Monad

```lean
namespace Effects.Free
  -- Free monad for effects
  inductive Free (α : Type u) where
    | pure : α → Free α
    | bind : Free α → (α → Free β) → Free β
    | op : OperationType → Free α
end
```

## Handler Interface

### Handler Class

```lean
class Handler (m : Type u → Type v) where
  handle : Free α → m α
  -- Handler-specific methods
end
```

### Handler Laws

```lean
-- Monad morphism laws
theorem handle_pure : handle (pure x) = pure x
theorem handle_bind : handle (bind m f) = bind (handle m) (handle ∘ f)
theorem handle_op : handle (op op) = handleOp op
```

## Fusion Theorems

### Catamorphism

```lean
def fold {α β : Type u} (f : α → β) (g : OperationType → β) : Free α → β
```

### Fusion Laws

```lean
theorem fold_fusion : 
  ∀ f g h, fold f g ∘ fold h i = fold (f ∘ h) (g ∘ i)

theorem fold_pure : 
  ∀ f g x, fold f g (pure x) = f x

theorem fold_bind : 
  ∀ f g m h, fold f g (bind m h) = fold f g m >>= fold f g ∘ h
```

## Standard Library Effects

### State Effect

```lean
namespace State
  -- Operations
  def get : Free σ
  def put : σ → Free Unit
  
  -- Laws
  theorem put_get : ∀ s, get (put s ()) = s
  theorem get_put : ∀ s, put s (get ()) = ()
  
  -- Handler
  def handle : Handler (StateM σ)
end
```

### Reader Effect

```lean
namespace Reader
  -- Operations
  def read : Free ρ
  
  -- Laws
  theorem read_idempotent : ∀ r, read (read ()) = read ()
  
  -- Handler
  def handle : Handler (ReaderT ρ m)
end
```

### Writer Effect

```lean
namespace Writer
  -- Operations
  def write : ω → Free Unit
  def getOutput : Free ω
  
  -- Laws
  theorem write_getOutput : ∀ w, getOutput (write w ()) = w
  
  -- Handler
  def handle [Monoid ω] : Handler (WriterM ω)
end
```

### Exception Effect

```lean
namespace Exception
  -- Operations
  def throw : ε → Free α
  def catch : (ε → α) → α → Free α
  
  -- Laws
  theorem throw_catch : ∀ h e, catch h (throw e) = h e
  theorem catch_throw : ∀ h x, catch h (throw x) = h x
  
  -- Handler
  def handle : Handler (Except ε)
end
```

### Nondet Effect

```lean
namespace Nondet
  -- Operations
  def empty : Free α
  def choice : α → α → Free α
  
  -- Laws
  theorem choice_assoc : ∀ x y z, choice (choice x y) z = choice x (choice y z)
  theorem choice_comm : ∀ x y, choice x y = choice y x
  theorem choice_idemp : ∀ x, choice x x = x
  
  -- Handler
  def handle : Handler (ListM α)
end
```

## Composition

### Sum Theory

```lean
def SumTheory (T1 T2 : Type u → Type v) : Type u → Type v
```

### Product Theory

```lean
def ProdTheory (T1 T2 : Type u → Type v) : Type u → Type v
```

### Composition Laws

```lean
theorem sum_assoc : 
  SumTheory (SumTheory T1 T2) T3 = SumTheory T1 (SumTheory T2 T3)

theorem prod_assoc : 
  ProdTheory (ProdTheory T1 T2) T3 = ProdTheory T1 (ProdTheory T2 T3)

theorem sum_prod_distrib : 
  SumTheory (ProdTheory T1 T2) (ProdTheory T1 T3) = 
  ProdTheory T1 (SumTheory T2 T3)
```

## Tactics

### Effect Fusion

```lean
elab "effect_fuse!" : tactic
```

**Description**: Proves catamorphism/handler fusion shapes with bounded search.

**Usage**:
```lean
theorem my_fusion : 
  fold f g ∘ fold h i = fold (f ∘ h) (g ∘ i) := by
  effect_fuse!
```

**Guarantees**:
- Bounded search (max 1000 steps)
- Fixed lemma order
- No unbounded backtracking
- Clear failure messages

### Handler Laws

```lean
elab "handler_laws!" : tactic
```

**Description**: Discharges monad-morphism and theory equation obligations.

**Usage**:
```lean
instance : Handler MyEffect (StateM σ) where
  handle := fun
    | MyEffect.Free.pure x => pure x
    | MyEffect.Free.op op => handleOp op
  
  -- Automatically prove laws
  handler_laws!
```

**Guarantees**:
- Proves all required laws
- Bounded search
- Clear error messages for failures

## Configuration

### Codegen Options

```lean
-- Timeout for code generation (milliseconds)
set_option effects.codegen.timeoutMs 8000

-- Enable/disable tracing
set_option effects.codegen.trace false

-- Inline proofs in generated code
set_option effects.codegen.inlineProofs true
```

### Performance Options

```lean
-- Maximum fusion depth
set_option effects.fusion.maxDepth 10

-- Enable aggressive optimization
set_option effects.optimization.aggressive true

-- Memory limit for codegen
set_option effects.codegen.memoryLimit 1024
```

## Error Handling

### Common Errors

#### Codegen Timeout
```
Error: Code generation timed out after 8000ms
```
**Solution**: Increase timeout or simplify equations

#### Invalid Type in Operation
```
Error: Type 'List α' not allowed in operation signature
```
**Solution**: Use only Unit, products, sums, and parameters

#### Circular Equation Dependency
```
Error: Circular dependency in equations
```
**Solution**: Restructure equations to avoid cycles

#### Handler Law Failure
```
Error: Handler law 'handle_bind' failed
```
**Solution**: Check handler implementation for monad laws

### Debugging

#### Enable Tracing
```lean
set_option effects.codegen.trace true
set_option effects.fusion.trace true
```

#### Verbose Error Messages
```lean
set_option effects.codegen.verbose true
```

#### Performance Profiling
```lean
set_option effects.profiling.enabled true
```

## Examples

### Basic Usage

```lean
import Effects.Std

-- Define a simple effect
theory Counter where
  op increment : Unit ⟶ Unit
  op getCount : Unit ⟶ Nat
  eq increment_getCount : ∀ n, getCount (increment ()) = n + 1
end

derive_effect Counter [free, handler, fusion, simp]

-- Use the effect
def countUp : Counter.Free Unit := do
  Counter.increment ()
  Counter.increment ()
  Counter.increment ()

-- Run with handler
def result : StateM Nat Unit :=
  Counter.handle.handle countUp
```

### Advanced Composition

```lean
-- Combine multiple effects
def StateReaderWriter (σ ρ ω : Type u) := 
  SumTheory (State σ) (SumTheory (Reader ρ) (Writer ω))

-- Handler for combined effects
def StateReaderWriter.handle [Monoid ω] : 
  StateReaderWriter.Handler (StateT σ (ReaderT ρ (WriterM ω))) where
  handle := fun
    | StateReaderWriter.Free.pure x => pure x
    | StateReaderWriter.Free.inl (State.Free.get _) => 
        get >>= pure
    | StateReaderWriter.Free.inl (State.Free.put s _) => 
        put s
    | StateReaderWriter.Free.inr (SumTheory.inl (Reader.Free.read _)) => 
        ask >>= pure
    | StateReaderWriter.Free.inr (SumTheory.inr (Writer.Free.write w _)) => 
        tell w
    | StateReaderWriter.Free.inr (SumTheory.inr (Writer.Free.getOutput _)) => 
        get
```

This API reference provides complete documentation for all core functionality in lean-effects. For more specific examples and advanced usage patterns, see the [Cookbook](cookbook/common-patterns.md) and [Examples](examples/) sections.
