-- State + Exception combination tests
import Effects
import Effects.Std.State
import Effects.Std.Exception
import Effects.Compose.Sum

namespace StateExceptionTest

-- Combined State + Exception signature
inductive StateExceptionSig (σ ε : Type u) (α : Type u) where
  | state : StateSig σ α → StateExceptionSig σ ε α
  | exception : ExceptionSig ε α → StateExceptionSig σ ε α

-- Functor instance for StateExceptionSig
instance {σ ε : Type u} : Functor (StateExceptionSig σ ε) where
  map f := fun m => match m with
    | .state fx => .state (f <$> fx)
    | .exception fx => .exception (f <$> fx)

-- Free monad for State + Exception
def StateException.Free (σ ε α : Type u) : Type u :=
  FreeMonad (StateExceptionSig σ ε) α

-- Operations for State + Exception
def StateException.get (σ ε : Type u) : StateException.Free σ ε σ :=
  .impure (.state .get) (fun x => .pure x)

def StateException.put (σ ε : Type u) (s : σ) : StateException.Free σ ε Unit :=
  .impure (.state (.put s)) (fun _ => .pure ())

def StateException.throw (σ ε : Type u) (e : ε) : StateException.Free σ ε α :=
  .impure (.exception (.throw e)) (fun _ => .pure (panic! "Exception.throw - this should never be reached"))

-- Combined State + Exception monad transformer
def StateExceptionT (σ ε : Type u) (M : Type u → Type u) [Monad M] (α : Type u) : Type u :=
  σ → M (Except ε (α × σ))

-- Monad instance for StateExceptionT
instance [Monad M] : Monad (StateExceptionT σ ε M) where
  pure x := fun s => pure (.ok (x, s))
  bind m f := fun s => do
    match ← m s with
    | .ok (x, s') => f x s'
    | .error e => pure (.error e)

-- Handler implementation for State + Exception
instance [Monad M] : Handler (StateExceptionSig σ ε) (StateExceptionT σ ε M) where
  interpret := fun m => match m with
    | .pure x => fun s => pure (.ok (x, s))
    | .impure fx k => fun s => match fx with
      | .state fx' => match fx' with
        | .get => k s s
        | .put s' => k () s'
      | .exception fx' => match fx' with
        | .throw e => pure (.error e)
  interpret_pure := by simp
  interpret_bind := by
    intro m f
    induction m with
    | pure x => simp
    | impure fx k ih =>
      simp
      cases fx with
      | state fx' =>
        cases fx' with
        | get => simp; congr 1; ext y; exact ih y
        | put s' => simp; congr 1; ext y; exact ih y
      | exception fx' =>
        cases fx' with
        | throw e => simp

-- Test state + exception combination
def testStateException (s : Nat) : StateException.Free Nat String Nat :=
  StateException.get Nat String >>= fun current =>
    if current > 0 then
      StateException.put Nat String (current + 1) >>= fun _ =>
        pure current
    else
      StateException.throw Nat String "negative state" >>= fun _ =>
        pure current

-- Test state + exception laws
theorem testStateExceptionLaws (s : Nat) :
  StateExceptionT.run (testStateException s) s =
  if s > 0 then
    (.ok (s, s + 1))
  else
    (.error "negative state") := by
  simp [testStateException, StateExceptionT.run, StateException.get, StateException.put, StateException.throw, bind]

-- Run function for StateExceptionT
def StateExceptionT.run (m : StateExceptionT σ ε M α) (s : σ) : M (Except ε (α × σ)) :=
  m s

-- Test the implementation
#eval StateExceptionT.run (testStateException 5) 0
#eval StateExceptionT.run (testStateException 0) 0

end StateExceptionTest
