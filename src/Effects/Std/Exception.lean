-- Exception effect theory and implementation
import Effects.Core.Free
import Effects.Core.Handler

namespace Effects.Std

open Effects.Core

universe u

inductive ExceptionSig (ε : Type u) : Type u → Type u where
  | throw {α : Type u} (e : ε) : ExceptionSig ε α

instance {ε : Type u} : Functor (ExceptionSig ε) where
  map _ x := match x with
    | .throw e => .throw e

abbrev Exception.Free (ε α : Type u) : Type (u + 1) :=
  FreeMonad (ExceptionSig ε) α

def Exception.throw {α : Type u} [Inhabited α] (ε : Type u) (e : ε) : Exception.Free ε α :=
  FreeMonad.impureOp (X := α) (ExceptionSig.throw e) (fun _ => FreeMonad.pure default)

def ExceptionT (ε : Type u) (M : Type u → Type u) [Monad M] (α : Type u) : Type u :=
  M (Except ε α)

instance {ε : Type u} {M : Type u → Type u} [Monad M] : Monad (ExceptionT ε M) where
  pure {α} x := @monadPure M _ (Except ε α) (Except.ok x)
  bind {α β} m f :=
    @monadBind M _ (Except ε α) (Except ε β) m fun r => match r with
      | Except.ok x => f x
      | Except.error e => @monadPure M _ (Except ε β) (Except.error e)

def ExceptionT.runFree {ε : Type u} {M : Type u → Type u} [Monad M] {α : Type u}
    (m : FreeMonad (ExceptionSig ε) α) : ExceptionT ε M α :=
  match m with
  | .pure x => @monadPure M _ (Except ε α) (Except.ok x)
  | .impure _ (.throw e) _ => @monadPure M _ (Except ε α) (Except.error e)

@[simp]
theorem ExceptionT.runFree_bind {ε : Type u} {M : Type u → Type u} [Monad M] [LawfulMonad M] {α β : Type u}
    (m : Exception.Free ε α) (f : α → Exception.Free ε β) :
    ExceptionT.runFree (FreeMonad.bind m f) =
      @monadBind M _ (Except ε α) (Except ε β) (ExceptionT.runFree m) fun r => match r with
        | Except.ok x => ExceptionT.runFree (f x)
        | Except.error e => @monadPure M _ (Except ε β) (Except.error e) := by
  induction m with
  | pure x =>
    cases f x with
    | pure y => simp [FreeMonad.bind, ExceptionT.runFree, monadBind, monadPure, bind, monad_pure_bind]
    | impure _ op k' =>
      cases op with
      | throw e => simp [FreeMonad.bind, ExceptionT.runFree, monadBind, monadPure, bind]
  | impure _ op k =>
    cases op with
    | throw e => simp [FreeMonad.bind, ExceptionT.runFree, monadBind, monadPure, bind]

instance {ε : Type u} {M : Type u → Type u} [Monad M] [LawfulMonad M] : Handler (ExceptionSig ε) (ExceptionT ε M) where
  interpret := ExceptionT.runFree
  interpret_pure := fun {α} x => rfl
  interpret_bind := fun {α β} m f => ExceptionT.runFree_bind m f

def Exception.run {ε α : Type u} (m : Exception.Free ε α) : Except ε α :=
  ExceptionT.runFree (M := Id) m

def Exception.catch {ε α : Type u} (m : Exception.Free ε α) (h : ε → Exception.Free ε α) :
    Exception.Free ε α :=
  match m with
  | .pure x => .pure x
  | .impure _ (.throw e) _ => h e

def ExceptionT.catch {ε α : Type u} {M : Type u → Type u} [Monad M]
    (m : ExceptionT ε M α) (h : ε → ExceptionT ε M α) : ExceptionT ε M α :=
  @monadBind M _ (Except ε α) (Except ε α) m fun r => match r with
    | Except.ok x => @monadPure M _ (Except ε α) (Except.ok x)
    | Except.error e => h e

end Effects.Std
