-- Generic free monad construction for algebraic effects
import Lean

namespace Effects.Core

/-- Target-monad `pure` (disambiguated from `FreeMonad.pure`). -/
def monadPure {M : Type u → Type u} [Monad M] {α : Type u} (x : α) : M α :=
  pure x

/-- Target-monad `bind` (disambiguated from `FreeMonad.bind`). -/
def monadBind {M : Type u → Type u} [Monad M] {α β : Type u} (m : M α) (f : α → M β) : M β :=
  bind m f

/-- Free monad for an effect signature functor `F`.

The continuation type `X` is explicit so handlers can recover operation result types. -/
inductive FreeMonad (F : Type u → Type u) (α : Type u) where
  | pure : α → FreeMonad F α
  | impure : (X : Type u) → F X → (X → FreeMonad F α) → FreeMonad F α

/-- Lift an effect operation with its result type. -/
def FreeMonad.impureOp [Functor F] {X α : Type u} (fx : F X) (k : X → FreeMonad F α) : FreeMonad F α :=
  .impure X fx k

def FreeMonad.bind (m : FreeMonad F α) (f : α → FreeMonad F β) : FreeMonad F β :=
  match m with
  | .pure x => f x
  | .impure x fx k => .impure x fx (fun y => FreeMonad.bind (k y) f)

def FreeMonad.map [Functor F] (f : α → β) (m : FreeMonad F α) : FreeMonad F β :=
  match m with
  | .pure x => .pure (f x)
  | .impure x fx k => .impure x fx (fun y => FreeMonad.map f (k y))

instance [Functor F] : Functor (FreeMonad F) where
  map := FreeMonad.map

instance freeMonadMonad : Monad (FreeMonad F) where
  pure := FreeMonad.pure
  bind := FreeMonad.bind

theorem pure_bind (x : α) (f : α → FreeMonad F β) :
    bind (pure x) f = f x := rfl

theorem bind_pure (m : FreeMonad F α) :
    FreeMonad.bind m pure = m := by
  induction m with
  | pure x => rfl
  | impure _ fx k ih =>
    simp only [FreeMonad.bind]
    congr 1
    funext y
    exact ih y

theorem bind_assoc (m : FreeMonad F α) (f : α → FreeMonad F β) (g : β → FreeMonad F γ) :
    FreeMonad.bind (FreeMonad.bind m f) g = FreeMonad.bind m (fun x => FreeMonad.bind (f x) g) := by
  induction m with
  | pure x => rfl
  | impure _ fx k ih =>
    simp only [FreeMonad.bind]
    congr 1
    funext y
    exact ih y

def op [Functor F] (fx : F α) : FreeMonad F α :=
  FreeMonad.impureOp fx (fun x => .pure x)

namespace FreeMonad

@[simp]
theorem bind_pure_simp [Functor F] (x : α) (f : α → FreeMonad F β) :
    bind (pure x) f = f x := pure_bind x f

@[simp]
theorem bind_pure_eta [Functor F] (m : FreeMonad F α) :
    bind m pure = m := bind_pure m

@[simp]
theorem bind_assoc_simp [Functor F] (m : FreeMonad F α) (f : α → FreeMonad F β) (g : β → FreeMonad F γ) :
    bind (bind m f) g = bind m (fun x => bind (f x) g) := bind_assoc m f g

@[simp]
theorem map_id [Functor F] (m : FreeMonad F α) :
    id <$> m = m := by
  induction m with
  | pure x => rfl
  | impure _ fx k ih =>
    simp only [Functor.map, FreeMonad.map]
    congr 1
    funext y
    exact ih y

@[simp]
theorem map_comp [Functor F] (f : α → β) (g : β → γ) (m : FreeMonad F α) :
    (g ∘ f) <$> m = g <$> (f <$> m) := by
  induction m with
  | pure x => rfl
  | impure _ fx k ih =>
    simp only [Functor.map, FreeMonad.map]
    congr 1
    funext y
    exact ih y

end FreeMonad

def FreeMonad.mapM [Functor F] [Monad M] [Monad N] (h : M α → N α) (m : FreeMonad F α) : FreeMonad F α :=
  match m with
  | .pure x => .pure x
  | .impure x fx k => .impure x fx (fun y => mapM h (k y))

def FreeMonad.fold [Functor F] [Monad M] (φ : F (M α) → M α) (m : FreeMonad F α) : M α :=
  match m with
  | .pure x => monadPure (M := M) x
  | .impure _ fx k => φ (Functor.map (fun x => FreeMonad.fold φ (k x)) fx)

abbrev Free := FreeMonad

def FreeMonad.interpret [Functor F] [Monad M] (φ : F (M α) → M α) : FreeMonad F α → M α :=
  FreeMonad.fold φ

@[simp]
theorem FreeMonad.fold_pure [Functor F] [Monad M] (φ : F (M α) → M α) (x : α) :
    FreeMonad.fold φ (FreeMonad.pure x) = monadPure (M := M) x := by
  unfold FreeMonad.fold monadPure
  rfl

@[simp]
theorem FreeMonad.interpret_pure [Functor F] [Monad M] (φ : F (M α) → M α) (x : α) :
    FreeMonad.interpret φ (FreeMonad.pure x) = monadPure (M := M) x :=
  FreeMonad.fold_pure φ x

end Effects.Core
