-- Handler typeclass and laws for algebraic effects
import Effects.Core.Free
import Lean

namespace Effects.Core

class Handler (F : Type u → Type u) (M : Type u → Type u) [Functor F] [Monad M] where
  interpret : {α : Type u} → FreeMonad F α → M α
  interpret_pure : ∀ {α : Type u} (x : α), interpret (FreeMonad.pure x) = monadPure x
  interpret_bind : ∀ {α β : Type u} (m : FreeMonad F α) (f : α → FreeMonad F β),
    interpret (FreeMonad.bind m f) = monadBind (interpret m) (fun x => interpret (f x))

-- Helper functors for effect composition (used by Core.Fusion and Compose)
inductive SumFunctor (F G : Type u → Type u) (α : Type u) where
  | inl : F α → SumFunctor F G α
  | inr : G α → SumFunctor F G α

inductive ProductFunctor (F G : Type u → Type u) (α : Type u) where
  | mk : F α → G α → ProductFunctor F G α

instance [Functor F] [Functor G] : Functor (SumFunctor F G) where
  map f := fun m => match m with
    | .inl fx => .inl (f <$> fx)
    | .inr gx => .inr (f <$> gx)

instance [Functor F] [Functor G] : Functor (ProductFunctor F G) where
  map f := fun m => match m with
    | .mk fx gx => .mk (f <$> fx) (f <$> gx)

export Handler (interpret interpret_pure interpret_bind)

/-- Target-monad `pure_bind` (disambiguated from `FreeMonad.pure_bind`). -/
theorem monad_pure_bind [Monad M] [LawfulMonad M] (x : α) (f : α → M β) :
    monadBind (monadPure (M := M) x) f = f x := by
  simp [monadBind, monadPure, LawfulMonad.pure_bind]

/-- Target-monad `bind_assoc` (disambiguated from `FreeMonad.bind_assoc`). -/
theorem monad_bind_assoc [Monad M] [LawfulMonad M] (m : M α) (f : α → M β) (g : β → M γ) :
    monadBind (monadBind m f) g = monadBind m (fun x => monadBind (f x) g) := by
  simp [monadBind, LawfulMonad.bind_assoc]

end Effects.Core
