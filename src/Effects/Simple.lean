-- Simple Effects module
import Lean

namespace Effects

-- Simple free monad
inductive FreeMonad (F : Type u → Type u) (α : Type u) where
  | pure : α → FreeMonad F α
  | op : F (FreeMonad F α) → FreeMonad F α

-- Simple bind
def FreeMonad.bind [Functor F] (m : FreeMonad F α) (f : α → FreeMonad F β) : FreeMonad F β :=
  match m with
  | .pure x => f x
  | .op fx => .op (bind · f <$> fx)

-- Monad instance
instance [Functor F] : Monad (FreeMonad F) where
  pure := FreeMonad.pure
  bind := FreeMonad.bind

end Effects
