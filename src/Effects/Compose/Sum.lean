-- Sum composition for algebraic effects
import Effects.Core.Free
import Effects.Core.Handler

namespace Effects.Compose

open Effects.Core

universe u

abbrev Sum.Free (F G : Type u → Type u) [Functor F] [Functor G] (α : Type u) : Type (u + 1) :=
  FreeMonad (SumFunctor F G) α

def Sum.inl {F G : Type u → Type u} [Functor F] [Functor G] (fx : F α) : Sum.Free F G α :=
  FreeMonad.impureOp (SumFunctor.inl fx) (fun x => FreeMonad.pure x)

def Sum.inr {F G : Type u → Type u} [Functor F] [Functor G] (gx : G α) : Sum.Free F G α :=
  FreeMonad.impureOp (SumFunctor.inr gx) (fun x => FreeMonad.pure x)

def Sum.runHandler {F G : Type u → Type u} [Functor F] [Functor G] {M : Type u → Type u} [Monad M]
    {α : Type u} (hF : ∀ {β}, F β → M β) (hG : ∀ {β}, G β → M β)
    (m : FreeMonad (SumFunctor F G) α) : M α :=
  match m with
  | .pure x => pure x
  | .impure _ fx k => match fx with
    | .inl fx' => hF fx' >>= fun x => Sum.runHandler hF hG (k x)
    | .inr gx' => hG gx' >>= fun x => Sum.runHandler hF hG (k x)

@[simp]
theorem Sum.runHandler_bind {F G : Type u → Type u} [Functor F] [Functor G] {M : Type u → Type u} [Monad M] [LawfulMonad M]
    {α β : Type u} (hF : ∀ {X}, F X → M X) (hG : ∀ {X}, G X → M X)
    (m : FreeMonad (SumFunctor F G) α) (f : α → FreeMonad (SumFunctor F G) β) :
    Sum.runHandler hF hG (FreeMonad.bind m f) =
      bind (Sum.runHandler hF hG m) (fun x => Sum.runHandler hF hG (f x)) := by
  induction m with
  | pure x => simp [Sum.runHandler, FreeMonad.bind, monad_pure_bind]
  | impure _ fx k ih =>
    cases fx with
    | inl fx' =>
      simp only [Sum.runHandler, FreeMonad.bind, bind]
      rw [LawfulMonad.bind_assoc]
      congr 1; funext y; exact ih y
    | inr gx' =>
      simp only [Sum.runHandler, FreeMonad.bind, bind]
      rw [LawfulMonad.bind_assoc]
      congr 1; funext y; exact ih y

@[reducible]
def Sum.handler {F G : Type u → Type u} [Functor F] [Functor G] {M : Type u → Type u} [Monad M] [LawfulMonad M]
    (hF : ∀ {α}, F α → M α) (hG : ∀ {α}, G α → M α) : Handler (SumFunctor F G) M where
  interpret := Sum.runHandler hF hG
  interpret_pure := fun {α} x => rfl
  interpret_bind := fun {α β} m f => Sum.runHandler_bind hF hG m f

def Sum.runLiftHandler {F G : Type u → Type u} [Functor F] [Functor G]
    {M N : Type u → Type u} [Monad M] [Monad N] {α : Type u}
    (hF : ∀ {β}, F β → M β) (hG : ∀ {β}, G β → M β) (lift : ∀ {β}, M β → N β)
    (m : FreeMonad (SumFunctor F G) α) : N α :=
  match m with
  | .pure x => pure x
  | .impure _ fx k => match fx with
    | .inl fx' => lift (hF fx') >>= fun x => Sum.runLiftHandler hF hG lift (k x)
    | .inr gx' => lift (hG gx') >>= fun x => Sum.runLiftHandler hF hG lift (k x)

@[simp]
theorem Sum.runLiftHandler_bind {F G : Type u → Type u} [Functor F] [Functor G]
    {M N : Type u → Type u} [Monad M] [Monad N] [LawfulMonad N] {α β : Type u}
    (hF : ∀ {X}, F X → M X) (hG : ∀ {X}, G X → M X) (lift : ∀ {X}, M X → N X)
    (m : FreeMonad (SumFunctor F G) α) (f : α → FreeMonad (SumFunctor F G) β) :
    Sum.runLiftHandler hF hG lift (FreeMonad.bind m f) =
      bind (Sum.runLiftHandler hF hG lift m) (fun x => Sum.runLiftHandler hF hG lift (f x)) := by
  induction m with
  | pure x => simp [Sum.runLiftHandler, FreeMonad.bind, monad_pure_bind]
  | impure _ fx k ih =>
    cases fx with
    | inl fx' =>
      simp only [Sum.runLiftHandler, FreeMonad.bind, bind]
      rw [LawfulMonad.bind_assoc]
      congr 1; funext y; exact ih y
    | inr gx' =>
      simp only [Sum.runLiftHandler, FreeMonad.bind, bind]
      rw [LawfulMonad.bind_assoc]
      congr 1; funext y; exact ih y

@[reducible]
def Sum.liftHandler {F G : Type u → Type u} [Functor F] [Functor G]
    {M N : Type u → Type u} [Monad M] [Monad N] [LawfulMonad N]
    (hF : ∀ {α}, F α → M α) (hG : ∀ {α}, G α → M α) (lift : ∀ {α}, M α → N α) :
    Handler (SumFunctor F G) N where
  interpret := Sum.runLiftHandler hF hG lift
  interpret_pure := fun {α} x => rfl
  interpret_bind := fun {α β} m f => Sum.runLiftHandler_bind hF hG lift m f

end Effects.Compose
