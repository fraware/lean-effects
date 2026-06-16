-- Catamorphism fusion (optional; imported by tactics, not by stable `Effects.Core`)
import Effects.Core.Free
import Effects.Core.Handler

namespace Effects.Core

section Fusion

variable {F : Type u → Type u} [Functor F] [LawfulFunctor F]
variable {M N : Type u → Type u} [Monad M] [Monad N] [LawfulMonad M] [LawfulMonad N]

theorem FreeMonad.fold_fusion_basic (φ : F (M α) → M α) (ψ : F (N α) → N α) (h : M α → N α)
    (h_pure : ∀ x, h (monadPure (M := M) x) = monadPure (M := N) x)
    (h_op : ∀ fx, h (φ fx) = ψ (Functor.map h fx)) :
    ∀ m, h (FreeMonad.fold φ m) = FreeMonad.fold ψ (FreeMonad.mapM h m) := by
  intro m
  induction m with
  | pure x =>
    simp [FreeMonad.fold, FreeMonad.mapM, h_pure]
  | impure _ fx k ih =>
    simp only [FreeMonad.fold, FreeMonad.mapM, h_op, Functor.map_map]
    rw [funext ih]

end Fusion

end Effects.Core
