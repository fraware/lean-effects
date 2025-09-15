-- State effect theory and implementation
import Effects.Core.Free
import Effects.Core.Handler
import Effects.Core.Fusion
import Effects.DSL.Syntax
import Lean

namespace Effects.Std

-- State effect signature - operations for getting and setting state
inductive StateSig (σ : Type u) (α : Type u) where
  | get : StateSig σ α
  | put : σ → StateSig σ α

-- Functor instance for StateSig
instance {σ : Type u} : Functor (StateSig σ) where
  map f := fun m => match m with
    | .get => .get
    | .put s => .put s

-- State theory definition according to the production spec
def StateTheory (σ : Type u) : Theory where
  name := "State"
  params := [⟨"σ", "Type u"⟩]
  ops := [
    ⟨"get", Ty.unit, Ty.param "σ"⟩,
    ⟨"put", Ty.param "σ", Ty.unit⟩
  ]
  eqns := [
    ⟨"put_get",
     Term.op "put" [Term.var "s"] ∘ Term.op "get" [Term.unit],
     Term.var "s"⟩
  ]

-- Free monad for State effect
def State.Free (σ α : Type u) : Type u :=
  FreeMonad (StateSig σ) α

-- State operations
def State.get (σ : Type u) : State.Free σ σ :=
  .impure .get (fun x => .pure x)

def State.put (σ : Type u) (s : σ) : State.Free σ Unit :=
  .impure (.put s) (fun _ => .pure ())

-- StateT monad transformer
def StateT (σ : Type u) (M : Type u → Type u) [Monad M] (α : Type u) : Type u :=
  σ → M (α × σ)

-- Monad instance for StateT
instance [Monad M] : Monad (StateT σ M) where
  pure x := fun s => pure (x, s)
  bind m f := fun s => do
    let (x, s') ← m s
    f x s'

-- Operation interpretation for State
def State.interpretOp {σ α : Type u} [Monad M] (fx : StateSig σ α) : M α :=
  match fx with
  | .get => pure (panic! "State.get should be handled by StateT")
  | .put s => pure (panic! "State.put should be handled by StateT")

-- Proper interpretOp for StateT
def StateT.interpretOp {σ α : Type u} [Monad M] (fx : StateSig σ α) (s : σ) : M (α × σ) :=
  match fx with
  | .get => pure (s, s)
  | .put s' => pure ((), s')

-- State handler implementation
instance [Monad M] : Handler (StateSig σ) (StateT σ M) where
  interpret := fun m => match m with
    | .pure x => fun s => pure (x, s)
    | .impure fx k => fun s => match fx with
      | .get => k s s
      | .put s' => k () s'
  interpret_pure := by simp
  interpret_bind := by
    intro m f
    induction m with
    | pure x => simp
    | impure fx k ih =>
      simp
      cases fx with
      | get => simp; congr 1; ext y; exact ih y
      | put s' => simp; congr 1; ext y; exact ih y

-- State handler laws
theorem state_handler_pure [Monad M] (x : α) :
  interpret (pure x : State.Free σ α) = pure x := by
  simp [Handler.interpret_pure]

theorem state_handler_bind [Monad M] (m : State.Free σ α) (f : α → State.Free σ β) :
  interpret (bind m f) = bind (interpret m) (fun x => interpret (f x)) := by
  simp [Handler.interpret_bind]

theorem state_handler_get [Monad M] :
  interpret (State.get σ) = fun s => pure (s, s) := by
  simp [State.get, interpret]

theorem state_handler_put [Monad M] (s : σ) :
  interpret (State.put σ s) = fun _ => pure ((), s) := by
  simp [State.put, interpret]

-- State equations - put_get law
theorem state_put_get [Monad M] (s : σ) :
  interpret (State.put σ s >>= fun _ => State.get σ) = fun _ => pure (s, s) := by
  simp [state_handler_bind, state_handler_put, state_handler_get]

-- State fusion theorems
theorem state_fusion [Monad M] [Monad N] (h : M α → N α) :
  h ∘ interpret = interpret ∘ (h <$> ·) := by
  ext m s
  simp [interpret]
  induction m with
  | pure x => simp [Handler.interpret_pure]
  | impure fx k ih =>
    simp [Handler.interpret_bind]
    cases fx with
    | get => simp; congr 1; ext y; exact ih y
    | put s' => simp; congr 1; ext y; exact ih y

-- State simplification lemmas
@[simp]
theorem state_pure_bind [Monad M] (x : α) (f : α → State.Free σ β) :
  bind (pure x : State.Free σ α) f = f x := by
  simp [bind, FreeMonad.pure_bind]

@[simp]
theorem state_bind_pure [Monad M] (m : State.Free σ α) :
  bind m pure = m := by
  simp [bind, FreeMonad.bind_pure]

@[simp]
theorem state_bind_assoc [Monad M] (m : State.Free σ α) (f : α → State.Free σ β) (g : β → State.Free σ γ) :
  bind (bind m f) g = bind m (fun x => bind (f x) g) := by
  simp [bind, FreeMonad.bind_assoc]

-- State run function
def State.run (m : State.Free σ α) (s : σ) : α × σ :=
  let handler := interpret m (M := Id)
  handler s

-- State eval function (returns only the value)
def State.eval (m : State.Free σ α) (s : σ) : α :=
  (State.run m s).1

-- State exec function (returns only the state)
def State.exec (m : State.Free σ α) (s : σ) : σ :=
  (State.run m s).2

-- State modification
def State.modify (σ : Type u) (f : σ → σ) : State.Free σ Unit :=
  State.get σ >>= fun s => State.put σ (f s)

-- State modification with return value
def State.modifyGet (σ : Type u) (f : σ → α × σ) : State.Free σ α :=
  State.get σ >>= fun s =>
    let (a, s') := f s
    State.put σ s' >>= fun _ => pure a

-- State gets (get with transformation)
def State.gets (σ : Type u) (f : σ → α) : State.Free σ α :=
  State.get σ >>= fun s => pure (f s)

-- Export the main State functionality
export State (get put modify modifyGet gets run eval exec)
export State.Free

end Effects.Std
