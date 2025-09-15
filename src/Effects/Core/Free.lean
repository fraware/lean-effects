-- Generic free monad construction for algebraic effects
import Lean

namespace Effects.Core

-- Free monad construction for algebraic effects
-- This is the standard free monad construction that satisfies strict positivity
inductive FreeMonad (F : Type u → Type u) (α : Type u) where
  -- Pure values
  | pure : α → FreeMonad F α
  -- Effect operations - F X represents an operation that produces an X
  -- The continuation (X → FreeMonad F α) handles the result
  | impure : F X → (X → FreeMonad F α) → FreeMonad F α

-- Monadic bind for FreeMonad
def FreeMonad.bind [Functor F] (m : FreeMonad F α) (f : α → FreeMonad F β) : FreeMonad F β :=
  match m with
  | .pure x => f x
  | .impure fx k => .impure fx (fun x => FreeMonad.bind (k x) f)

-- Map function for FreeMonad
def FreeMonad.map [Functor F] (f : α → β) (m : FreeMonad F α) : FreeMonad F β :=
  match m with
  | .pure x => .pure (f x)
  | .impure fx k => .impure fx (fun x => FreeMonad.map f (k x))

-- Functor instance for FreeMonad
instance [Functor F] : Functor (FreeMonad F) where
  map := FreeMonad.map

-- Monad instance for FreeMonad
instance [Functor F] : Monad (FreeMonad F) where
  pure := FreeMonad.pure
  bind := FreeMonad.bind

-- Monad laws for FreeMonad - these are definitional
theorem pure_bind [Functor F] (x : α) (f : α → FreeMonad F β) :
  bind (pure x) f = f x := by
  rfl

theorem bind_pure [Functor F] (m : FreeMonad F α) :
  FreeMonad.bind m pure = m := by
  induction m with
  | pure x => rfl
  | impure fx k ih =>
    simp only [FreeMonad.bind]
    congr 1
    funext y
    exact ih y

theorem bind_assoc [Functor F] (m : FreeMonad F α) (f : α → FreeMonad F β) (g : β → FreeMonad F γ) :
  FreeMonad.bind (FreeMonad.bind m f) g = FreeMonad.bind m (fun x => FreeMonad.bind (f x) g) := by
  induction m with
  | pure x => rfl
  | impure fx k ih =>
    simp only [FreeMonad.bind]
    congr 1
    funext y
    exact ih y

-- Operation constructor - lift an effect operation into the free monad
def op [Functor F] (fx : F α) : FreeMonad F α := .impure fx (fun x => .pure x)

-- Simplification lemmas for the free monad
namespace FreeMonad

-- β-reduction for bind
@[simp]
theorem bind_pure_simp [Functor F] (x : α) (f : α → FreeMonad F β) :
  bind (pure x) f = f x := pure_bind x f

-- η-expansion for bind
@[simp]
theorem bind_pure_eta [Functor F] (m : FreeMonad F α) :
  bind m pure = m := bind_pure m

-- Associativity of bind
@[simp]
theorem bind_assoc_simp [Functor F] (m : FreeMonad F α) (f : α → FreeMonad F β) (g : β → FreeMonad F γ) :
  bind (bind m f) g = bind m (fun x => bind (f x) g) := bind_assoc m f g

-- Functor laws
@[simp]
theorem map_id [Functor F] (m : FreeMonad F α) :
  id <$> m = m := by
  induction m with
  | pure x => rfl
  | impure fx k ih =>
    simp only [Functor.map, id, FreeMonad.map]
    congr 1
    funext y
    exact ih y

@[simp]
theorem map_comp [Functor F] (f : α → β) (g : β → γ) (m : FreeMonad F α) :
  (g ∘ f) <$> m = g <$> (f <$> m) := by
  induction m with
  | pure x => rfl
  | impure fx k ih =>
    simp only [Functor.map, FreeMonad.map]
    congr 1
    funext y
    exact ih y

end FreeMonad

-- MapM function for transforming monads
def FreeMonad.mapM [Functor F] [Monad M] [Monad N] (h : M α → N α) (m : FreeMonad F α) : FreeMonad F α :=
  match m with
  | .pure x => .pure x
  | .impure fx k => .impure fx (fun x => mapM h (k x))

-- Fold function for catamorphisms
def FreeMonad.fold [Functor F] [Monad M] (φ : F (M α) → M α) (m : FreeMonad F α) : M α :=
  match m with
  | .pure x => pure x
  | .impure fx k => φ (Functor.map (FreeMonad.fold φ) fx)

-- Export the main types and functions
export FreeMonad (pure bind map mapM fold)

end Effects.Core
