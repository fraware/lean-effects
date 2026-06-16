-- Writer effect theory and implementation
import Mathlib.Algebra.Group.Defs
import Effects.Core.Free
import Effects.Core.Handler
import Effects.Core.SigUtil

namespace Effects.Std

open Effects.Core

universe u

inductive WriterSig (Chunk : Type u) : Type u → Type u where
  | tell : Chunk → WriterSig Chunk PUnit

noncomputable instance {Chunk : Type u} : Functor (WriterSig Chunk) where
  map f x := mapConst f x

abbrev Writer.Free (Chunk : Type u) (α : Type u) : Type (u + 1) :=
  FreeMonad (WriterSig Chunk) α

def Writer.tell (Chunk : Type u) (w : Chunk) : Writer.Free Chunk PUnit :=
  FreeMonad.impure PUnit (WriterSig.tell w) (fun _ => FreeMonad.pure PUnit.unit)

def WriterT (Chunk : Type u) (M : Type u → Type u) [Monad M] (α : Type u) : Type u :=
  M (α × Chunk)

instance {Chunk : Type u} {M : Type u → Type u} [Monoid Chunk] [Monad M] : Monad (WriterT Chunk M) where
  pure {α} x := @monadPure M _ (α × Chunk) (x, 1)
  bind {α β} m f :=
    @monadBind M _ (α × Chunk) (β × Chunk) m fun (x, w) =>
      @monadBind M _ (β × Chunk) (β × Chunk) (f x) fun (y, w') =>
        @monadPure M _ (β × Chunk) (y, w * w')

def WriterT.runFree {Chunk : Type u} {M : Type u → Type u} [Monoid Chunk] [Monad M] {α : Type u}
    (m : FreeMonad (WriterSig Chunk) α) : WriterT Chunk M α :=
  match m with
  | .pure x => @monadPure M _ (α × Chunk) (x, 1)
  | .impure _ (WriterSig.tell w) k =>
    @monadBind M _ (α × Chunk) (α × Chunk) (WriterT.runFree (k PUnit.unit)) fun (x, w') =>
      @monadPure M _ (α × Chunk) (x, w * w')

@[simp]
theorem WriterT.runFree_bind {Chunk : Type u} {M : Type u → Type u} [Monoid Chunk] [Monad M] [LawfulMonad M] {α β : Type u}
    (m : Writer.Free Chunk α) (f : α → Writer.Free Chunk β) :
    WriterT.runFree (FreeMonad.bind m f) =
      @monadBind M _ (α × Chunk) (β × Chunk) (WriterT.runFree m) fun (x, w) =>
        @monadBind M _ (β × Chunk) (β × Chunk) (WriterT.runFree (f x)) fun (y, w') =>
          @monadPure M _ (β × Chunk) (y, w * w') := by
  induction m with
  | pure x => simp [WriterT.runFree, monadBind, monadPure, bind, monad_pure_bind, FreeMonad.bind]
  | impure _ op k ih =>
    cases op with
    | tell w =>
      simp only [WriterT.runFree, FreeMonad.bind]
      suffices h :
          WriterT.runFree (FreeMonad.bind (k PUnit.unit) f) =
            @monadBind M _ (α × Chunk) (β × Chunk) (WriterT.runFree (k PUnit.unit)) fun (p : α × Chunk) =>
              @monadBind M _ (β × Chunk) (β × Chunk) (WriterT.runFree (f p.1)) fun (q : β × Chunk) =>
                @monadPure M _ (β × Chunk) (q.1, p.2 * q.2) by
        rw [h]
        simp only [monadBind, monadPure, bind, LawfulMonad.bind_assoc, LawfulMonad.pure_bind]
        congr 1
        funext x₀w₀
        rcases x₀w₀ with ⟨x₀, w₀⟩
        congr 1
        funext yw'
        rcases yw' with ⟨y, w'⟩
        simp [mul_assoc]
      simpa using ih PUnit.unit

instance {Chunk : Type u} {M : Type u → Type u} [Monoid Chunk] [Monad M] [LawfulMonad M] :
    Handler (WriterSig Chunk) (WriterT Chunk M) where
  interpret := WriterT.runFree
  interpret_pure := fun {α} x => rfl
  interpret_bind := WriterT.runFree_bind

def Writer.run {Chunk : Type u} {α : Type u} [Monoid Chunk] (m : Writer.Free Chunk α) : α × Chunk :=
  WriterT.runFree (M := Id) m

def Writer.eval {Chunk : Type u} {α : Type u} [Monoid Chunk] (m : Writer.Free Chunk α) : α :=
  (Writer.run m).1

def Writer.exec {Chunk : Type u} {α : Type u} [Monoid Chunk] (m : Writer.Free Chunk α) : Chunk :=
  (Writer.run m).2

end Effects.Std
