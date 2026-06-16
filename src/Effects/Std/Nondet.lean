-- Nondeterminism effect theory and implementation
import Effects.Core.Free
import Effects.Core.Handler

namespace Effects.Std

open Effects.Core

universe u

inductive NondetSig : Type u → Type u where
  | empty {α : Type u} : NondetSig α
  | choice {α : Type u} : α → α → NondetSig α

instance : Functor NondetSig where
  map f x := match x with
    | .empty => .empty
    | .choice x y => .choice (f x) (f y)

abbrev Nondet.Free (α : Type u) : Type (u + 1) :=
  FreeMonad NondetSig α

def Nondet.empty {α : Type u} [Inhabited α] : Nondet.Free α :=
  FreeMonad.impureOp (X := PUnit) NondetSig.empty (fun _ => FreeMonad.pure default)

def Nondet.choice {α : Type u} (x y : α) : Nondet.Free α :=
  FreeMonad.impureOp (NondetSig.choice x y) (fun z => FreeMonad.pure z)

def NondetT (M : Type u → Type u) [Monad M] (α : Type u) : Type u :=
  M (List α)

instance {M : Type u → Type u} [Monad M] : Monad (NondetT M) where
  pure {α} x := @monadPure M _ (List α) [x]
  bind {α β} m f :=
    @monadBind M _ (List α) (List β) m fun xs =>
      @monadBind M _ (List (List β)) (List β) (xs.mapM f) fun yss =>
        @monadPure M _ (List β) yss.flatten

def NondetT.runFree {A : Type u} {M : Type u → Type u} [Monad M]
    (m : FreeMonad NondetSig A) : M (List A) :=
  match m with
  | .pure x => @monadPure M _ (List A) [x]
  | .impure _ (.empty) _ => @monadPure M _ (List A) []
  | .impure _ (.choice x y) k =>
    @monadBind M _ (List A) (List A) (NondetT.runFree (k x)) fun xs =>
      @monadBind M _ (List A) (List A) (NondetT.runFree (k y)) fun ys =>
        @monadPure M _ (List A) (xs ++ ys)

@[simp]
theorem NondetT.runFree_bind {M : Type u → Type u} [Monad M] [LawfulMonad M] {α β : Type u}
    (m : Nondet.Free α) (f : α → Nondet.Free β) :
    NondetT.runFree (FreeMonad.bind m f) =
      @monadBind M _ (List α) (List β) (NondetT.runFree m) fun xs =>
        @monadBind M _ (List (List β)) (List β) (xs.mapM fun x => NondetT.runFree (f x)) fun yss =>
          @monadPure M _ (List β) yss.flatten := by
  induction m with
  | pure x =>
    simp [FreeMonad.bind, NondetT.runFree, monadBind, monadPure, monad_pure_bind]
  | impure _ op k ih =>
    cases op with
    | empty => simp [FreeMonad.bind, NondetT.runFree, monadBind, monadPure]
    | choice x y =>
      simp only [NondetT.runFree, FreeMonad.bind, monadBind, bind]
      sorry

instance {M : Type u → Type u} [Monad M] [LawfulMonad M] : Handler NondetSig (NondetT M) where
  interpret := NondetT.runFree
  interpret_pure := fun {_} _ => rfl
  interpret_bind := fun {_} {_} m f => NondetT.runFree_bind m f

def Nondet.run {α : Type u} (m : Nondet.Free α) : List α :=
  NondetT.runFree (M := Id) m

def Nondet.toList {α : Type u} (m : Nondet.Free α) : List α :=
  Nondet.run m

def Nondet.first {α : Type u} (m : Nondet.Free α) : Option α :=
  (Nondet.run m).head?

end Effects.Std