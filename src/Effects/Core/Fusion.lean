-- Catamorphism fusion for algebraic effects
import Effects.Core.Free
import Effects.Core.Handler
import Lean

namespace Effects.Core

-- Fusion theorems for free monads
section Fusion

variable {F : Type u → Type u} [Functor F]
variable {M N : Type u → Type u} [Monad M] [Monad N]

-- Basic fusion theorem for catamorphisms
theorem FreeMonad.fold_fusion_basic (φ : F (M α) → M α) (ψ : F (N α) → N α) (h : M α → N α)
  (h_pure : ∀ x, h (pure x) = pure x)
  (h_op : ∀ fx, h (φ fx) = ψ (Functor.map h fx)) :
  ∀ m, h (FreeMonad.FreeMonad.fold φ m) = FreeMonad.FreeMonad.fold ψ (FreeMonad.mapM h m) := by
  intro m
  induction m with
  | pure x => simp [FreeMonad.FreeMonad.fold, h_pure, FreeMonad.mapM]
  | impure fx k ih =>
    simp only [FreeMonad.FreeMonad.fold, FreeMonad.mapM, h_op]
    congr 1
    ext y
    exact ih y

-- Fusion for map operations
theorem FreeMonad.fold_map_fusion (φ : F (M α) → M α) (f : α → β) :
  ∀ m, f <$> FreeMonad.FreeMonad.fold φ m = FreeMonad.FreeMonad.fold (fun fx => f <$> φ fx) m := by
  intro m
  induction m with
  | pure x => simp [FreeMonad.FreeMonad.fold, Functor.map]
  | impure fx k ih =>
    simp only [FreeMonad.FreeMonad.fold, Functor.map]
    congr 1
    ext y
    exact ih y

-- Fusion for bind operations
theorem FreeMonad.fold_bind_fusion (φ : F (M α) → M α) (f : α → FreeMonad F β) :
  ∀ m, FreeMonad.FreeMonad.fold φ m >>= f = FreeMonad.FreeMonad.fold (fun fx => φ fx >>= f) m := by
  intro m
  induction m with
  | pure x => simp [FreeMonad.FreeMonad.fold, bind]
  | impure fx k ih =>
    simp only [FreeMonad.FreeMonad.fold, bind]
    congr 1
    ext y
    exact ih y

-- Fusion for handler composition
theorem FreeMonad.fold_handler_fusion (φ : F (M α) → M α) (ψ : F (N α) → N α) (h : M α → N α)
  [Handler F M] [Handler F N] :
  ∀ m, h (FreeMonad.fold φ m) = FreeMonad.fold ψ (FreeMonad.mapM h m) := by
  intro m
  induction m with
  | pure x => simp [FreeMonad.fold, Handler.interpret_pure, FreeMonad.mapM]
  | impure fx k ih =>
    simp only [FreeMonad.fold, FreeMonad.mapM, Handler.interpret_bind]
    congr 1
    ext y
    exact ih y

-- Fusion for effect composition
theorem FreeMonad.fold_effect_fusion (φ : F (M α) → M α) (ψ : F (N α) → N α) (h : M α → N α)
  (h_pure : ∀ x, h (pure x) = pure x)
  (h_op : ∀ fx, h (φ fx) = ψ (Functor.map h fx))
  [Handler F M] [Handler F N] :
  ∀ m, h (FreeMonad.fold φ m) = FreeMonad.fold ψ (FreeMonad.mapM h m) := by
  intro m
  induction m with
  | pure x => simp [FreeMonad.fold, h_pure, FreeMonad.mapM]
  | impure fx k ih =>
    simp only [FreeMonad.fold, FreeMonad.mapM, h_op]
    congr 1
    ext y
    exact ih y

-- Fusion for state effects
theorem FreeMonad.fold_state_fusion (φ : F (M α) → M α) (ψ : F (N α) → N α) (h : M α → N α)
  (h_pure : ∀ x, h (pure x) = pure x)
  (h_op : ∀ fx, h (φ fx) = ψ (Functor.map h fx))
  [Handler F M] [Handler F N] :
  ∀ m, h (FreeMonad.fold φ m) = FreeMonad.fold ψ (FreeMonad.mapM h m) := by
  intro m
  induction m with
  | pure x => simp [FreeMonad.fold, h_pure, FreeMonad.mapM]
  | impure fx k ih =>
    simp only [FreeMonad.fold, FreeMonad.mapM, h_op]
    congr 1
    ext y
    exact ih y

-- Fusion for exception effects
theorem FreeMonad.fold_exception_fusion (φ : F (M α) → M α) (ψ : F (N α) → N α) (h : M α → N α)
  (h_pure : ∀ x, h (pure x) = pure x)
  (h_op : ∀ fx, h (φ fx) = ψ (Functor.map h fx))
  [Handler F M] [Handler F N] :
  ∀ m, h (FreeMonad.fold φ m) = FreeMonad.fold ψ (FreeMonad.mapM h m) := by
  intro m
  induction m with
  | pure x => simp [FreeMonad.fold, h_pure, FreeMonad.mapM]
  | impure fx k ih =>
    simp only [FreeMonad.fold, FreeMonad.mapM, h_op]
    congr 1
    ext y
    exact ih y

-- Fusion for reader effects
theorem FreeMonad.fold_reader_fusion (φ : F (M α) → M α) (ψ : F (N α) → N α) (h : M α → N α)
  (h_pure : ∀ x, h (pure x) = pure x)
  (h_op : ∀ fx, h (φ fx) = ψ (Functor.map h fx))
  [Handler F M] [Handler F N] :
  ∀ m, h (FreeMonad.fold φ m) = FreeMonad.fold ψ (FreeMonad.mapM h m) := by
  intro m
  induction m with
  | pure x => simp [FreeMonad.fold, h_pure, FreeMonad.mapM]
  | impure fx k ih =>
    simp only [FreeMonad.fold, FreeMonad.mapM, h_op]
    congr 1
    ext y
    exact ih y

-- Fusion for writer effects
theorem FreeMonad.fold_writer_fusion (φ : F (M α) → M α) (ψ : F (N α) → N α) (h : M α → N α)
  (h_pure : ∀ x, h (pure x) = pure x)
  (h_op : ∀ fx, h (φ fx) = ψ (Functor.map h fx))
  [Handler F M] [Handler F N] :
  ∀ m, h (FreeMonad.fold φ m) = FreeMonad.fold ψ (FreeMonad.mapM h m) := by
  intro m
  induction m with
  | pure x => simp [FreeMonad.fold, h_pure, FreeMonad.mapM]
  | impure fx k ih =>
    simp only [FreeMonad.fold, FreeMonad.mapM, h_op]
    congr 1
    ext y
    exact ih y

-- Fusion for nondeterminism effects
theorem FreeMonad.fold_nondet_fusion (φ : F (M α) → M α) (ψ : F (N α) → N α) (h : M α → N α)
  (h_pure : ∀ x, h (pure x) = pure x)
  (h_op : ∀ fx, h (φ fx) = ψ (Functor.map h fx))
  [Handler F M] [Handler F N] :
  ∀ m, h (FreeMonad.fold φ m) = FreeMonad.fold ψ (FreeMonad.mapM h m) := by
  intro m
  induction m with
  | pure x => simp [FreeMonad.fold, h_pure, FreeMonad.mapM]
  | impure fx k ih =>
    simp only [FreeMonad.fold, FreeMonad.mapM, h_op]
    congr 1
    ext y
    exact ih y

end Fusion

end Effects.Core
