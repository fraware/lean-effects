-- Performance benchmarks for lean-effects
import Effects
import Mathlib.Data.List.Basic
import Mathlib.Data.Prod.Basic

namespace Effects.Bench

-- Benchmark state operations
def benchStateOps (n : Nat) : State.Free Nat Unit :=
  match n with
  | 0 => pure ()
  | n + 1 => do
    let s ← State.get Nat
    State.put Nat (s + 1)
    benchStateOps n

-- Benchmark exception handling
def benchExceptionOps (n : Nat) : Exception.Free String Unit :=
  match n with
  | 0 => pure ()
  | n + 1 => do
    if n % 2 = 0 then
      Exception.throw String "error"
    else
      benchExceptionOps n

-- Benchmark reader operations
def benchReaderOps (n : Nat) : Reader.Free Nat Nat :=
  match n with
  | 0 => pure 0
  | n + 1 => do
    let r ← Reader.ask Nat
    benchReaderOps n >>= fun x => pure (r + x)

-- Benchmark writer operations
def benchWriterOps (n : Nat) : Writer.Free String Unit :=
  match n with
  | 0 => pure ()
  | n + 1 => do
    Writer.tell String s!"step {n}"
    benchWriterOps n

-- Benchmark nondet operations
def benchNondetOps (n : Nat) : Nondet.Free Nat :=
  match n with
  | 0 => pure 0
  | n + 1 => do
    let x ← benchNondetOps n
    Nondet.choice (pure x) (pure (x + 1))

-- Benchmark combined effects
def benchStateException (n : Nat) : Sum.Free (StateSig Nat) (ExceptionSig String) Unit :=
  match n with
  | 0 => pure ()
  | n + 1 => do
    let s ← Sum.inl (StateSig Nat) (ExceptionSig String) (State.get Nat)
    if s > 100 then
      Sum.inr (StateSig Nat) (ExceptionSig String) (Exception.throw String "overflow")
    else
      Sum.inl (StateSig Nat) (ExceptionSig String) (State.put Nat (s + 1))
      benchStateException n

-- Benchmark handler performance
def benchHandler (m : State.Free Nat Nat) (s : Nat) : Nat × Nat :=
  State.run m s

-- Benchmark fusion performance
def benchFusion (m : State.Free Nat Nat) (f : Nat → State.Free Nat Nat) : State.Free Nat Nat :=
  bind m f

-- Benchmark simplification performance
def benchSimp (m : State.Free Nat Nat) : State.Free Nat Nat :=
  bind m pure

-- Benchmark composition performance
def benchCompose (m1 : State.Free Nat Nat) (m2 : Exception.Free String Nat) :
  Sum.Free (StateSig Nat) (ExceptionSig String) Nat :=
  Sum.inl (StateSig Nat) (ExceptionSig String) m1 >>= fun x =>
  Sum.inr (StateSig Nat) (ExceptionSig String) m2 >>= fun y =>
  pure (x + y)

-- Benchmark large programs
def benchLargeProgram (n : Nat) : State.Free Nat Nat :=
  let rec loop (i : Nat) (acc : Nat) : State.Free Nat Nat :=
    match i with
    | 0 => pure acc
    | i + 1 => do
      let s ← State.get Nat
      State.put Nat (s + 1)
      loop i (acc + s)
  loop n 0

-- Benchmark handler laws
def benchHandlerLaws (m : State.Free Nat Nat) : Prop :=
  State.run (bind m pure) = State.run m

-- Benchmark effect fusion
def benchEffectFusion (m : State.Free Nat Nat) (f : Nat → State.Free Nat Nat) : Prop :=
  State.run (bind m f) = fun s =>
    let (x, s') := State.run m s
    State.run (f x) s'

-- Benchmark equations
def benchEquations (s : Nat) : Prop :=
  State.run (State.put Nat s >>= fun _ => State.get Nat) 0 = (s, s)

-- Benchmark tactics
def benchTactics (m : State.Free Nat Nat) : Prop :=
  State.run (bind m pure) = State.run m

-- Benchmark code generation
def benchCodeGen (n : Nat) : State.Free Nat Nat :=
  let rec loop (i : Nat) : State.Free Nat Nat :=
    match i with
    | 0 => pure 0
    | i + 1 => do
      let s ← State.get Nat
      State.put Nat (s + 1)
      loop i
  loop n

-- Benchmark memory usage
def benchMemory (n : Nat) : State.Free Nat (List Nat) :=
  let rec loop (i : Nat) (acc : List Nat) : State.Free Nat (List Nat) :=
    match i with
    | 0 => pure acc
    | i + 1 => do
      let s ← State.get Nat
      State.put Nat (s + 1)
      loop i (s :: acc)
  loop n []

-- Benchmark determinism
def benchDeterminism (n : Nat) : State.Free Nat Nat :=
  let rec loop (i : Nat) : State.Free Nat Nat :=
    match i with
    | 0 => pure 0
    | i + 1 => do
      let s ← State.get Nat
      State.put Nat (s + 1)
      loop i
  loop n

end Effects.Bench
