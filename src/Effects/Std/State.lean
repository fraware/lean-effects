-- State effect theory and implementation
import Effects.Core.Free
import Effects.Core.Handler
import Effects.Core.SigUtil

namespace Effects.Std

open Effects.Core

universe u

inductive StateSig (σ : Type u) : Type u → Type u where
  | get : StateSig σ σ
  | put : σ → StateSig σ PUnit

noncomputable instance {σ : Type u} : Functor (StateSig σ) where
  map f x := mapConst f x

abbrev State.Free (σ α : Type u) : Type (u + 1) :=
  FreeMonad (StateSig σ) α

def State.get (σ : Type u) : State.Free σ σ :=
  FreeMonad.impure σ StateSig.get (fun s => FreeMonad.pure s)

def State.put (σ : Type u) (s : σ) : State.Free σ PUnit :=
  FreeMonad.impure PUnit (StateSig.put s) (fun _ => FreeMonad.pure PUnit.unit)

def StateT (σ : Type u) (M : Type u → Type u) [Monad M] (α : Type u) : Type u :=
  σ → M (α × σ)

instance {σ : Type u} {M : Type u → Type u} [Monad M] : Monad (StateT σ M) where
  pure x := fun s => pure (x, s)
  bind m f := fun s => do
    let (x, s') ← m s
    f x s'

def State.run {σ α : Type u} (m : State.Free σ α) (s : σ) : α × σ :=
  match m with
  | .pure x => (x, s)
  | .impure _ StateSig.get k => State.run (k s) s
  | .impure _ (StateSig.put s') k => State.run (k PUnit.unit) s'

def State.eval {σ α : Type u} (m : State.Free σ α) (s : σ) : α :=
  (State.run m s).1

def State.exec {σ α : Type u} (m : State.Free σ α) (s : σ) : σ :=
  (State.run m s).2

def State.modify (σ : Type u) (f : σ → σ) : State.Free σ PUnit :=
  FreeMonad.bind (State.get σ) fun s => State.put σ (f s)

def State.modifyGet {α σ : Type u} (f : σ → α × σ) : State.Free σ α :=
  FreeMonad.bind (State.get σ) fun s =>
    let (a, s') := f s
    FreeMonad.bind (State.put σ s') fun _ => FreeMonad.pure a

def State.gets {α σ : Type u} (f : σ → α) : State.Free σ α :=
  FreeMonad.bind (State.get σ) fun s => FreeMonad.pure (f s)

def StateT.runFree {σ : Type u} {M : Type u → Type u} [Monad M] {α : Type u}
    (m : FreeMonad (StateSig σ) α) : StateT σ M α :=
  fun s => pure (State.run m s)

@[simp]
theorem State.run_bind {σ α β : Type u} (m : State.Free σ α) (f : α → State.Free σ β) (s : σ) :
    State.run (FreeMonad.bind m f) s =
      match State.run m s with
      | (x, s') => State.run (f x) s' := by
  induction m generalizing s with
  | pure x => simp [FreeMonad.bind, State.run]
  | impure _ op k ih =>
    cases op with
    | get =>
      simp only [FreeMonad.bind, State.run]
      exact (ih s) s
    | put s' =>
      simp only [FreeMonad.bind, State.run]
      exact (ih PUnit.unit) s'

noncomputable instance {σ : Type u} {M : Type u → Type u} [Monad M] [LawfulMonad M] : Handler (StateSig σ) (StateT σ M) where
  interpret := StateT.runFree
  interpret_pure := fun {α} x => funext fun s => rfl
  interpret_bind := fun {α β} m f => by
    funext s
    induction m generalizing s with
    | pure x =>
      simp [StateT.runFree, monadBind, monadPure, bind, State.run, FreeMonad.bind, LawfulMonad.pure_bind]
    | impure _ op k ih =>
      cases op with
      | get =>
        simp [StateT.runFree, monadBind, FreeMonad.bind, State.run_bind]
        exact (ih s) s
      | put s'' =>
        simp [StateT.runFree, monadBind, FreeMonad.bind, State.run_bind]
        exact (ih PUnit.unit) s''

@[simp]
theorem state_pure_bind {σ α β : Type u} (x : α) (f : α → State.Free σ β) :
    FreeMonad.bind (FreeMonad.pure x : State.Free σ α) f = f x := by
  simp [FreeMonad.bind_pure_simp]

@[simp]
theorem state_bind_pure {σ α : Type u} (m : State.Free σ α) :
    FreeMonad.bind m FreeMonad.pure = m := by
  simp [FreeMonad.bind_pure_eta]

@[simp]
theorem state_bind_assoc {σ α β γ : Type u} (m : State.Free σ α) (f : α → State.Free σ β)
    (g : β → State.Free σ γ) :
    FreeMonad.bind (FreeMonad.bind m f) g = FreeMonad.bind m (fun x => FreeMonad.bind (f x) g) := by
  simp [FreeMonad.bind_assoc_simp]

end Effects.Std
