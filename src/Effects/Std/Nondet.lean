-- Nondeterminism effect theory and implementation
import Effects.Core.Free
import Effects.Core.Handler

namespace Effects.Std

open Effects.Core

universe u

/-- Monads whose effects commute, as required for nondeterministic choice. -/
class BindCommute (M : Type u → Type u) [Monad M] where
  commute_bind_bind {α β γ : Type u} (ma : M α) (mb : M β) (k : α → β → M γ) :
    bind ma (fun a => bind mb (fun b => k a b)) =
    bind mb (fun b => bind ma (fun a => k a b))

instance : BindCommute Id where
  commute_bind_bind := fun _ _ _ => rfl

instance : BindCommute Option where
  commute_bind_bind ma mb k := by
    cases ma <;> cases mb <;> simp [bind]

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

/-- Sequential `mapM`/`flatten` on two appended list computations. -/
private theorem bind_flatten_mapM_append_bind {M : Type u → Type u} [Monad M] [LawfulMonad M]
    {α β : Type u} (mx my : M (List α)) (g : α → M (List β)) :
    (@monadBind M _ (List β) (List β)
      (@monadBind M _ (List α) (List β) mx fun xs =>
        @monadBind M _ (List (List β)) (List β) (xs.mapM g) fun yss =>
          @monadPure M _ (List β) yss.flatten)
      fun xs' =>
        @monadBind M _ (List β) (List β)
          (@monadBind M _ (List α) (List β) my fun ys =>
            @monadBind M _ (List (List β)) (List β) (ys.mapM g) fun yss =>
              @monadPure M _ (List β) yss.flatten)
          fun ys' => @monadPure M _ (List β) (xs' ++ ys')) =
    @monadBind M _ (List α) (List β) mx fun xs =>
      @monadBind M _ (List (List β)) (List β) (xs.mapM g) fun yss_x =>
        @monadBind M _ (List α) (List β) my fun ys =>
          @monadBind M _ (List (List β)) (List β) (ys.mapM g) fun yss_y =>
            @monadPure M _ (List β) (yss_x.flatten ++ yss_y.flatten) := by
  simp [monadBind, monadPure, LawfulMonad.bind_assoc]

private theorem monadBind_bind_assoc {M : Type u → Type u} [Monad M] [LawfulMonad M]
    {α β γ : Type u} (mx : M α) (f : α → M β) (g : β → M γ) :
    @monadBind M _ β γ (@monadBind M _ α β mx f) g =
    @monadBind M _ α γ mx fun a => @monadBind M _ β γ (f a) g := by
  simp [monadBind, LawfulMonad.bind_assoc]

/-- `mapM` then `flatten` distributes over appended lists inside a bind. -/
private theorem bind_append_mapM_flatten {M : Type u → Type u} [Monad M] [LawfulMonad M] [BindCommute M]
    {α β : Type u} (xs : List α) (my : M (List α)) (g : α → M (List β)) :
    bind my (fun ys =>
      bind ((xs ++ ys).mapM g) (fun yss => pure yss.flatten)) =
    bind (xs.mapM g) (fun yss_x =>
      bind my (fun ys =>
        bind (ys.mapM g) (fun yss_y => pure (yss_x.flatten ++ yss_y.flatten)))) := by
  rw [← (BindCommute.commute_bind_bind my (xs.mapM g) (fun ys tx =>
    bind (ys.mapM g) (fun ty => pure (tx.flatten ++ ty.flatten))))]
  apply bind_congr
  intro ys
  have happend :
      (xs ++ ys).mapM g =
        bind (xs.mapM g) (fun tx => bind (ys.mapM g) (fun ty => pure (tx ++ ty))) := by
    simpa [bind, monadBind, monadPure] using
      (List.mapM_append (l₁ := xs) (l₂ := ys) (f := g))
  rw [happend]
  simp [bind, LawfulMonad.bind_assoc, LawfulMonad.pure_bind, List.flatten_append]

@[simp]
theorem NondetT.runFree_bind {M : Type u → Type u} [Monad M] [LawfulMonad M] [BindCommute M] {α β : Type u}
    (m : Nondet.Free α) (f : α → Nondet.Free β) :
    NondetT.runFree (FreeMonad.bind m f) =
      @monadBind M _ (List α) (List β) (NondetT.runFree m) fun xs =>
        @monadBind M _ (List (List β)) (List β) (xs.mapM fun x => NondetT.runFree (f x)) fun yss =>
          @monadPure M _ (List β) yss.flatten := by
  induction m with
  | pure x =>
    simp [FreeMonad.bind, NondetT.runFree, monadBind, monadPure]
  | impure _ op k ih =>
    cases op with
    | empty => simp [FreeMonad.bind, NondetT.runFree, monadBind, monadPure]
    | choice x y =>
      simp only [NondetT.runFree, FreeMonad.bind]
      rw [ih x, ih y, bind_flatten_mapM_append_bind]
      apply Eq.symm
      rw [monadBind_bind_assoc]
      apply congrArg (fun h => @monadBind M _ (List α) (List β) (NondetT.runFree (k x)) h)
      funext xs
      rw [monadBind_bind_assoc]
      simp only [monadBind, monadPure, LawfulMonad.pure_bind]
      exact bind_append_mapM_flatten (M := M) xs (NondetT.runFree (k y)) (fun z => NondetT.runFree (f z))

instance {M : Type u → Type u} [Monad M] [LawfulMonad M] [BindCommute M] :
    Handler NondetSig (NondetT M) where
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
