-- Production specification example
-- This file demonstrates the DSL usage according to the production spec
import Effects

namespace Effects.Examples.ProductionSpec

-- Example 1: Define a simple State theory using the DSL
-- This would be the ideal syntax according to the production spec:
--
-- theory State (σ : Type u) where
--   op get  : Unit ⟶ σ
--   op put  : σ    ⟶ Unit
--   eq put_get : ∀ s, get (put s ()) = s
-- end
--
-- derive_effect State [free, handler, fusion, simp]
--
-- For now, we'll use the manually implemented State effect

-- Example 2: Use the State effect
def stateExample : State.Free Nat Nat := do
  let s ← State.get Nat
  State.put Nat (s + 1)
  State.get Nat

-- Example 3: Use the Exception effect
def exceptionExample : Exception.Free String Nat := do
  Exception.throw String "error"

-- Example 4: Use the Reader effect
def readerExample : Reader.Free Nat Nat := do
  let r ← Reader.ask Nat
  pure (r * 2)

-- Example 5: Use the Writer effect
def writerExample : Writer.Free String Nat := do
  Writer.tell String "hello"
  Writer.tell String "world"
  pure 42

-- Example 6: Use the Nondet effect
def nondetExample : Nondet.Free Nat := do
  Nondet.choice (pure 1) (pure 2)

-- Example 7: Demonstrate effect composition (conceptual)
-- In the full implementation, this would use SumTheory and ProductTheory
def combinedExample : State.Free Nat Nat := do
  let s ← State.get Nat
  if s > 0 then
    State.put Nat (s - 1)
    State.get Nat
  else
    -- This would be Exception.throw "negative state" in a composed effect
    pure 0

-- Example 8: Demonstrate handler usage
def runStateExample (s : Nat) : Nat × Nat :=
  State.run stateExample s

def runExceptionExample : Except String Nat :=
  Exception.run exceptionExample

def runReaderExample (r : Nat) : Nat :=
  Reader.run readerExample r

def runWriterExample : Nat × String :=
  Writer.run writerExample

def runNondetExample : List Nat :=
  Nondet.run nondetExample

-- Example 9: Demonstrate fusion theorems
theorem stateFusionExample (m : State.Free Nat α) (f : α → β) :
  State.run (f <$> m) = fun s =>
    let (x, s') := State.run m s
    (f x, s') := by
  simp [State.run, Functor.map]

-- Example 10: Demonstrate simplification lemmas
theorem stateSimplificationExample (x : α) (f : α → State.Free Nat β) :
  bind (pure x : State.Free Nat α) f = f x := by
  simp [bind, pure_bind]

-- Example 11: Demonstrate handler laws
theorem stateHandlerLawsExample (x : α) (s : Nat) :
  State.run (pure x : State.Free Nat α) s = (x, s) := by
  simp [State.run, pure]

-- Example 12: Demonstrate effect equations
theorem stateEquationsExample (s : Nat) :
  State.run (State.put Nat s >>= fun _ => State.get Nat) 0 = (s, s) := by
  simp [State.run, State.put, State.get, bind]

-- Example 13: Demonstrate monad morphism properties
theorem stateMonadMorphismExample (m : State.Free Nat α) (f : α → State.Free Nat β) (s : Nat) :
  State.run (bind m f) s =
  let (x, s') := State.run m s
  State.run (f x) s' := by
  simp [State.run, bind]

-- Example 14: Demonstrate functor laws
theorem stateFunctorLawsExample (m : State.Free Nat α) :
  State.run (id <$> m) = State.run m := by
  simp [State.run, Functor.map, id]

-- Example 15: Demonstrate monad laws
theorem stateMonadLawsExample (m : State.Free Nat α) :
  State.run (bind m pure) = State.run m := by
  simp [State.run, bind, bind_pure]

-- Example 16: Demonstrate effect-specific operations
def stateModifyExample : State.Free Nat Unit :=
  State.modify Nat (fun n => n + 1)

def stateGetsExample : State.Free Nat Nat :=
  State.gets Nat (fun n => n * 2)

def exceptionCatchExample : Exception.Free String Nat :=
  Exception.catch (Exception.throw String "error") (fun _ => pure 42)

def readerAsksExample : Reader.Free Nat Nat :=
  Reader.asks Nat (fun n => n * 2)

def readerLocalExample : Reader.Free Nat Nat :=
  Reader.local Nat (fun n => n + 1) (Reader.ask Nat)

def writerTellReturnExample : Writer.Free String Nat :=
  Writer.tellReturn "hello" 42

def writerListenExample : Writer.Free String (Nat × String) :=
  Writer.listen writerExample

def nondetGuardExample : Nondet.Free Nat :=
  Nondet.guard (2 > 1) >>= fun _ => pure 42

def nondetFilterExample : Nondet.Free Nat :=
  Nondet.filter (fun n => n > 0) nondetExample

-- Example 17: Demonstrate performance characteristics
-- These would be benchmarked in the actual implementation
def performanceExample : State.Free Nat Nat := do
  let s ← State.get Nat
  State.put Nat (s + 1)
  let s' ← State.get Nat
  State.put Nat (s' + 1)
  State.get Nat

-- Example 18: Demonstrate deterministic proofs
-- All proofs in this file should be deterministic and byte-stable
theorem deterministicProofExample (s : Nat) :
  State.run (State.get Nat) s = (s, s) := by
  simp [State.run, State.get]

-- Example 19: Demonstrate bounded search
-- The tactics should have bounded search and fixed lemma order
theorem boundedSearchExample (m : State.Free Nat α) (f : α → β) :
  State.run (f <$> m) = fun s =>
    let (x, s') := State.run m s
    (f x, s') := by
  simp [State.run, Functor.map]

-- Example 20: Demonstrate stable builds
-- All proofs should be reproducible across CI
theorem stableBuildExample (x : α) (f : α → State.Free Nat β) :
  bind (pure x : State.Free Nat α) f = f x := by
  simp [bind, pure_bind]

end Effects.Examples.ProductionSpec
