-- Product composition for algebraic effects
import Effects.Core.Free
import Effects.Core.Handler

namespace Effects.Compose

open Effects.Core

universe u

abbrev Product.Free (F G : Type u → Type u) [Functor F] [Functor G] (α : Type u) : Type (u + 1) :=
  FreeMonad (ProductFunctor F G) α

def Product.mk {F G : Type u → Type u} [Functor F] [Functor G] (fx : F α) (gx : G α) : Product.Free F G α :=
  FreeMonad.impureOp (ProductFunctor.mk fx gx) (fun x => FreeMonad.pure x)

def Product.runHandler {F G : Type u → Type u} [Functor F] [Functor G] {M : Type u → Type u} [Monad M]
    {α : Type u} (hF : ∀ {β}, F β → M β) (hG : ∀ {β}, G β → M β)
    (m : FreeMonad (ProductFunctor F G) α) : M α :=
  match m with
  | .pure x => pure x
  | .impure _ (.mk fx' gx') k =>
    hF fx' >>= fun x => hG gx' >>= fun _ => Product.runHandler hF hG (k x)

@[simp]
theorem Product.runHandler_bind {F G : Type u → Type u} [Functor F] [Functor G] {M : Type u → Type u} [Monad M] [LawfulMonad M]
    {α β : Type u} (hF : ∀ {X}, F X → M X) (hG : ∀ {X}, G X → M X)
    (m : FreeMonad (ProductFunctor F G) α) (f : α → FreeMonad (ProductFunctor F G) β) :
    Product.runHandler hF hG (FreeMonad.bind m f) =
      bind (Product.runHandler hF hG m) (fun x => Product.runHandler hF hG (f x)) := by
  induction m with
  | pure x => simp [Product.runHandler, FreeMonad.bind, monad_pure_bind]
  | impure _ fx k ih =>
    cases fx with
    | mk fx' gx' =>
      simp only [Product.runHandler, FreeMonad.bind, bind]
      rw [LawfulMonad.bind_assoc]
      congr 1
      funext x
      rw [LawfulMonad.bind_assoc]
      congr 1
      funext _
      exact ih x

@[reducible]
def Product.handler {F G : Type u → Type u} [Functor F] [Functor G] {M : Type u → Type u} [Monad M] [LawfulMonad M]
    (hF : ∀ {α}, F α → M α) (hG : ∀ {α}, G α → M α) : Handler (ProductFunctor F G) M where
  interpret := Product.runHandler hF hG
  interpret_pure := fun {α} x => rfl
  interpret_bind := fun {α β} m f => Product.runHandler_bind hF hG m f

def Product.runLiftHandler {F G : Type u → Type u} [Functor F] [Functor G]
    {M N : Type u → Type u} [Monad M] [Monad N] {α : Type u}
    (hF : ∀ {β}, F β → M β) (hG : ∀ {β}, G β → M β) (lift : ∀ {β}, M β → N β)
    (m : FreeMonad (ProductFunctor F G) α) : N α :=
  match m with
  | .pure x => pure x
  | .impure _ (.mk fx' gx') k =>
    lift (hF fx') >>= fun x => lift (hG gx') >>= fun _ => Product.runLiftHandler hF hG lift (k x)

@[simp]
theorem Product.runLiftHandler_bind {F G : Type u → Type u} [Functor F] [Functor G]
    {M N : Type u → Type u} [Monad M] [Monad N] [LawfulMonad N] {α β : Type u}
    (hF : ∀ {X}, F X → M X) (hG : ∀ {X}, G X → M X) (lift : ∀ {X}, M X → N X)
    (m : FreeMonad (ProductFunctor F G) α) (f : α → FreeMonad (ProductFunctor F G) β) :
    Product.runLiftHandler hF hG lift (FreeMonad.bind m f) =
      bind (Product.runLiftHandler hF hG lift m) (fun x => Product.runLiftHandler hF hG lift (f x)) := by
  induction m with
  | pure x => simp [Product.runLiftHandler, FreeMonad.bind, monad_pure_bind]
  | impure _ fx k ih =>
    cases fx with
    | mk fx' gx' =>
      simp only [Product.runLiftHandler, FreeMonad.bind, bind]
      rw [LawfulMonad.bind_assoc]
      congr 1
      funext x
      rw [LawfulMonad.bind_assoc]
      congr 1
      funext _
      exact ih x

@[reducible]
def Product.liftHandler {F G : Type u → Type u} [Functor F] [Functor G]
    {M N : Type u → Type u} [Monad M] [Monad N] [LawfulMonad N]
    (hF : ∀ {α}, F α → M α) (hG : ∀ {α}, G α → M α) (lift : ∀ {α}, M α → N α) :
    Handler (ProductFunctor F G) N where
  interpret := Product.runLiftHandler hF hG lift
  interpret_pure := fun {α} x => rfl
  interpret_bind := fun {α β} m f => Product.runLiftHandler_bind hF hG lift m f

end Effects.Compose
