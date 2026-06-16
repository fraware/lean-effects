-- Reader effect theory and implementation
import Effects.Core.Free
import Effects.Core.Handler
import Effects.Core.SigUtil

namespace Effects.Std

open Effects.Core

universe u

inductive ReaderSig (ρ : Type u) : Type u → Type u where
  | ask : ReaderSig ρ ρ

noncomputable instance {ρ : Type u} : Functor (ReaderSig ρ) where
  map f x := mapConst f x

abbrev Reader.Free (ρ α : Type u) : Type (u + 1) :=
  FreeMonad (ReaderSig ρ) α

def Reader.ask (ρ : Type u) : Reader.Free ρ ρ :=
  FreeMonad.impure ρ ReaderSig.ask (fun x => FreeMonad.pure x)

def Reader.run {ρ α : Type u} (m : Reader.Free ρ α) (r : ρ) : α :=
  match m with
  | .pure x => x
  | .impure _ ReaderSig.ask k => Reader.run (k r) r

def ReaderT (ρ : Type u) (M : Type u → Type u) [Monad M] (α : Type u) : Type u :=
  ρ → M α

instance {ρ : Type u} {M : Type u → Type u} [Monad M] : Monad (ReaderT ρ M) where
  pure x := fun _ => pure x
  bind m f := fun r => do
    let x ← m r
    f x r

@[simp]
theorem Reader.run_bind {ρ α β : Type u} (m : Reader.Free ρ α) (f : α → Reader.Free ρ β) (r : ρ) :
    Reader.run (FreeMonad.bind m f) r = Reader.run (f (Reader.run m r)) r := by
  induction m with
  | pure x => simp [FreeMonad.bind, Reader.run]
  | impure X op k ih =>
    cases op with
    | ask =>
      simp only [FreeMonad.bind, Reader.run]
      exact ih r

def ReaderT.runFree {ρ : Type u} {M : Type u → Type u} [Monad M] {α : Type u}
    (m : FreeMonad (ReaderSig ρ) α) : ReaderT ρ M α :=
  match m with
  | .pure x => fun _ => pure x
  | .impure _ ReaderSig.ask k => fun r => ReaderT.runFree (k r) r

instance {ρ : Type u} {M : Type u → Type u} [Monad M] [LawfulMonad M] : Handler (ReaderSig ρ) (ReaderT ρ M) where
  interpret := ReaderT.runFree
  interpret_pure := fun {α} x => funext fun _ => rfl
  interpret_bind := fun {α β} m f => by
    funext r
    induction m generalizing r with
    | pure x => dsimp [ReaderT.runFree]; simp [monadBind, monad_pure_bind, bind]
    | impure _ op k ih =>
      cases op with
      | ask =>
        simp [ReaderT.runFree, monadBind, FreeMonad.bind, bind]
        exact (ih r) r

def Reader.local {ρ α : Type u} (f : ρ → ρ) (m : Reader.Free ρ α) : Reader.Free ρ α :=
  match m with
  | .pure x => .pure x
  | .impure _ ReaderSig.ask k =>
    FreeMonad.impure ρ ReaderSig.ask (fun r => Reader.local f (k r))

def ReaderT.local {ρ α : Type u} {M : Type u → Type u} [Monad M] (f : ρ → ρ) (m : ReaderT ρ M α) :
    ReaderT ρ M α :=
  fun r => m (f r)

end Effects.Std
