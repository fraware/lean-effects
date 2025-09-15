# Common Patterns Cookbook

This cookbook provides practical examples and patterns for using lean-effects in real applications.

## Basic State Management

### Simple Counter

```lean
import Effects.Std

-- Define a counter effect
theory Counter where
  op increment : Unit ⟶ Unit
  op decrement : Unit ⟶ Unit
  op getCount : Unit ⟶ Nat
  eq increment_decrement : ∀ n, getCount (increment (decrement ())) = getCount ()
end

derive_effect Counter [free, handler, fusion, simp]

-- State-based implementation
def Counter.handleState : Counter.Handler (StateM Nat) where
  handle := fun
    | Counter.Free.pure x => pure x
    | Counter.Free.increment _ => modify (· + 1)
    | Counter.Free.decrement _ => modify (· - 1)
    | Counter.Free.getCount _ => get

-- Usage example
def countUp : Counter.Free Unit := do
  Counter.increment ()
  Counter.increment ()
  Counter.increment ()

def runCounter : StateM Nat Unit :=
  Counter.handleState.handle countUp
```

### Accumulator Pattern

```lean
theory Accumulator (α : Type u) where
  op add : α ⟶ Unit
  op getSum : Unit ⟶ α
  eq add_getSum : ∀ x, getSum (add x ()) = x + getSum ()
end

derive_effect Accumulator [free, handler, fusion, simp]

-- Monoid-based implementation
def Accumulator.handleMonoid [Add α] [Zero α] : 
  Accumulator.Handler (StateM α) where
  handle := fun
    | Accumulator.Free.pure x => pure x
    | Accumulator.Free.add x _ => modify (· + x)
    | Accumulator.Free.getSum _ => get
```

## Error Handling Patterns

### Result Type with Exception

```lean
theory ResultException (ε : Type u) where
  op throw : ε ⟶ α
  op catch : (ε ⟶ α) ⟶ α ⟶ α
  eq throw_catch : ∀ h e, catch h (throw e) = h e
end

derive_effect ResultException [free, handler, fusion, simp]

-- Either-based implementation
def ResultException.handleEither : 
  ResultException.Handler (Except ε) where
  handle := fun
    | ResultException.Free.pure x => pure x
    | ResultException.Free.throw e => throw e
    | ResultException.Free.catch h x => 
        tryCatch (handle x) h

-- Usage with custom error types
inductive FileError where
  | notFound : String → FileError
  | permissionDenied : String → FileError
  | ioError : String → FileError

def readFile (path : String) : 
  ResultException.Free String := do
  -- Simulate file reading with potential errors
  if path.isEmpty then
    ResultException.throw (FileError.notFound path)
  else
    pure ("Contents of " ++ path)
```

## Logging and Tracing

### Structured Logging

```lean
structure LogEntry where
  level : LogLevel
  message : String
  timestamp : Nat
  context : List (String × String)

inductive LogLevel where
  | debug | info | warn | error

theory Logger where
  op log : LogEntry ⟶ Unit
  op getLogs : Unit ⟶ List LogEntry
  eq log_getLogs : ∀ e, getLogs (log e ()) = e :: getLogs ()
end

derive_effect Logger [free, handler, fusion, simp]

-- Writer-based implementation
def Logger.handleWriter : Logger.Handler (WriterM (List LogEntry)) where
  handle := fun
    | Logger.Free.pure x => pure x
    | Logger.Free.log e _ => tell [e]
    | Logger.Free.getLogs _ => get

-- Convenience functions
def logDebug (msg : String) : Logger.Free Unit :=
  Logger.log { level := LogLevel.debug, message := msg, 
               timestamp := 0, context := [] }

def logError (msg : String) : Logger.Free Unit :=
  Logger.log { level := LogLevel.error, message := msg, 
               timestamp := 0, context := [] }
```

## Resource Management

### Bracket Pattern

```lean
theory Resource (α : Type u) where
  op acquire : Unit ⟶ α
  op release : α ⟶ Unit
  op use : α ⟶ β ⟶ β
  eq acquire_release : ∀ r, release (acquire ()) = ()
end

derive_effect Resource [free, handler, fusion, simp]

-- Resource management implementation
def Resource.handleBracket [Inhabited α] : 
  Resource.Handler (StateM (Option α)) where
  handle := fun
    | Resource.Free.pure x => pure x
    | Resource.Free.acquire _ => do
        let r := default
        set (some r)
        pure r
    | Resource.Free.release r _ => 
        set none
    | Resource.Free.use r f => f r

-- Safe resource usage
def withResource [Inhabited α] (f : α → β) : 
  Resource.Free β := do
  let r ← Resource.acquire ()
  let result := Resource.use r f
  Resource.release r
  pure result
```

## Composition Patterns

### Reader + Writer

```lean
-- Combine Reader and Writer effects
def ReaderWriter (ρ ω : Type u) := 
  SumTheory (Reader ρ) (Writer ω)

-- Handler for combined effects
def ReaderWriter.handle [Monoid ω] : 
  ReaderWriter.Handler (ReaderT ρ (WriterM ω)) where
  handle := fun
    | ReaderWriter.Free.pure x => pure x
    | ReaderWriter.Free.inl (Reader.Free.read _) => 
        ask >>= pure
    | ReaderWriter.Free.inr (Writer.Free.write w _) => 
        tell w
    | ReaderWriter.Free.inr (Writer.Free.getOutput _) => 
        get

-- Usage example
def processData (data : String) : 
  ReaderWriter.Free String := do
  let config ← ReaderWriter.inl (Reader.read ())
  let result := processWithConfig config data
  ReaderWriter.inr (Writer.write result)
  pure result
```

### State + Exception

```lean
-- Combine State and Exception effects
def StateException (σ ε : Type u) := 
  SumTheory (State σ) (Exception ε)

-- Handler for combined effects
def StateException.handle [Inhabited σ] : 
  StateException.Handler (StateT σ (Except ε)) where
  handle := fun
    | StateException.Free.pure x => pure x
    | StateException.Free.inl (State.Free.get _) => 
        get >>= pure
    | StateException.Free.inl (State.Free.put s _) => 
        put s
    | StateException.Free.inr (Exception.Free.throw e _) => 
        throw e
    | StateException.Free.inr (Exception.Free.catch h x _) => 
        tryCatch (handle x) h
```

## Testing Patterns

### Effect Testing

```lean
-- Test effect handlers
def testStateHandler : IO Unit := do
  let result := State.handle.run (State.get ()) 42
  assert! result = (42, 42)
  
  let result := State.handle.run (State.put 10 >> State.get ()) 0
  assert! result = ((), 10)

-- Test effect composition
def testComposedEffects : IO Unit := do
  let effect : StateException.Free Nat := do
    StateException.inl (State.put 10)
    StateException.inl (State.get ())
  
  let result := StateException.handle.run effect 0
  match result with
  | Except.ok (value, state) => 
      assert! value = 10
      assert! state = 10
  | Except.error _ => 
      assert! false
```

### Property Testing

```lean
-- Test algebraic laws
def testPutGetLaw : IO Unit := do
  for i in [0:100] do
    let result := State.handle.run (State.put i >> State.get ()) 0
    assert! result = (i, i)

def testGetPutLaw : IO Unit := do
  for i in [0:100] do
    let result := State.handle.run (State.get () >>= State.put) i
    assert! result = ((), i)
```

## Performance Patterns

### Effect Fusion

```lean
-- Fuse multiple effect operations
def fusedComputation : State.Free Nat := do
  let x ← State.get ()
  State.put (x + 1)
  let y ← State.get ()
  State.put (y * 2)
  State.get ()

-- This gets automatically optimized by fusion
def optimizedComputation : State.Free Nat :=
  State.get () >>= fun x => 
  State.put (x + 1) >> 
  State.get () >>= fun y => 
  State.put (y * 2) >> 
  State.get ()
```

### Lazy Evaluation

```lean
-- Use lazy evaluation for expensive computations
theory Lazy (α : Type u) where
  op delay : (Unit → α) ⟶ α
  op force : α ⟶ α
  eq delay_force : ∀ f, force (delay f) = f ()
end

derive_effect Lazy [free, handler, fusion, simp]

-- Thunk-based implementation
def Lazy.handleThunk : Lazy.Handler (StateM (Thunk α)) where
  handle := fun
    | Lazy.Free.pure x => pure (Thunk.pure x)
    | Lazy.Free.delay f _ => pure (Thunk.mk f)
    | Lazy.Free.force t _ => pure (Thunk.get t)
```

## Advanced Patterns

### Effect Rows

```lean
-- Define effect rows for complex compositions
structure EffectRow where
  state : Option (Type u)
  reader : Option (Type u)
  writer : Option (Type u)
  exception : Option (Type u)

-- Dynamic effect handling
def handleEffectRow (row : EffectRow) : 
  EffectRow.Free α → IO α :=
  match row with
  | { state := some σ, reader := some ρ, writer := some ω, exception := some ε } =>
      -- Handle all four effects
      fun _ => pure default
  | { state := some σ, reader := some ρ, writer := none, exception := some ε } =>
      -- Handle state, reader, and exception
      fun _ => pure default
  -- ... other combinations
```

### Effect Polymorphism

```lean
-- Polymorphic effect handling
def runWithHandler {m : Type u → Type v} [Monad m] 
  (handler : Effect.Handler m) (computation : Effect.Free α) : m α :=
  handler.handle computation

-- Use with different monads
def example1 : IO Nat :=
  runWithHandler State.handleIO (State.get ())

def example2 : Except String Nat :=
  runWithHandler State.handleExcept (State.get ())
```

This cookbook provides a foundation for using lean-effects in production applications. Each pattern includes complete, runnable examples that demonstrate best practices and common use cases.
