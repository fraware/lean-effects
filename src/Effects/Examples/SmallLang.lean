-- Small language interpreter example
import Effects
import Mathlib.Data.List.Basic

namespace Effects.Examples

-- Define a small language with arithmetic and effects
inductive Expr where
  | lit : Nat → Expr
  | add : Expr → Expr → Expr
  | get : Expr
  | put : Expr → Expr
  | tell : Expr → Expr
  | throw : Expr → Expr
  | catch : Expr → Expr → Expr

-- Define the combined effect signature
inductive SmallLangSig (α : Type u) where
  | get : SmallLangSig α
  | put : Nat → SmallLangSig α
  | tell : String → SmallLangSig α
  | throw : String → SmallLangSig α

instance : Functor SmallLangSig where
  map f := fun m => match m with
    | .get => .get
    | .put n => .put n
    | .tell s => .tell s
    | .throw s => .throw s

-- Free monad for the small language
def SmallLang.Free (α : Type u) : Type u :=
  FreeMonad SmallLangSig α

-- Operations
def SmallLang.get : SmallLang.Free Nat :=
  .impure .get (fun x => .pure x)

def SmallLang.put (n : Nat) : SmallLang.Free Unit :=
  .impure (.put n) (fun _ => .pure ())

def SmallLang.tell (s : String) : SmallLang.Free Unit :=
  .impure (.tell s) (fun _ => .pure ())

def SmallLang.throw (s : String) : SmallLang.Free α :=
  .impure (.throw s) (fun _ => .pure (panic! "SmallLang.throw - this should never be reached"))

-- Interpreter for the small language
def interp (e : Expr) : SmallLang.Free Nat :=
  match e with
  | .lit n => pure n
  | .add e1 e2 => do
    let n1 ← interp e1
    let n2 ← interp e2
    pure (n1 + n2)
  | .get => SmallLang.get
  | .put e => do
    let n ← interp e
    SmallLang.put n
    pure 0
  | .tell e => do
    let n ← interp e
    SmallLang.tell s!"Value: {n}"
    pure n
  | .throw e => do
    let n ← interp e
    SmallLang.throw s!"Error: {n}"
  | .catch e1 e2 => do
    try
      interp e1
    catch
      interp e2

-- Handler for State + Writer + Exception
def StateWriterException (σ : Type u) (M : Type u → Type u) [Monad M] (α : Type u) : Type u :=
  σ → M (Except String (α × σ × List String))

instance [Monad M] : Monad (StateWriterException σ M) where
  pure x := fun s => pure (Except.ok (x, s, []))
  bind m f := fun s => do
    match ← m s with
    | Except.ok (x, s', log) => do
      match ← f x s' with
      | Except.ok (y, s'', log') => pure (Except.ok (y, s'', log ++ log'))
      | Except.error e => pure (Except.error e)
    | Except.error e => pure (Except.error e)

-- Handler implementation
instance [Monad M] : Handler SmallLangSig (StateWriterException Nat M) where
  interpret := fun m => match m with
    | .pure x => fun s => pure (Except.ok (x, s, []))
    | .impure fx k => fun s => match fx with
      | .get => k s s
      | .put n => k () n
      | .tell msg => k () s >>= fun (x, s', log) => pure (Except.ok (x, s', log ++ [msg]))
      | .throw msg => pure (Except.error msg)
  interpret_pure := by simp
  interpret_bind := by
    intro m f
    induction m with
    | pure x => simp
    | impure fx k ih =>
      simp
      cases fx with
      | get => simp; congr 1; ext y; exact ih y
      | put n => simp; congr 1; ext y; exact ih y
      | tell msg => simp; congr 1; ext y; exact ih y
      | throw msg => simp

-- Run the interpreter
def run (e : Expr) (s : Nat) : Except String (Nat × Nat × List String) :=
  interpret (interp e) s

-- Example programs
def example1 : Expr :=
  .add (.lit 1) (.add (.get) (.put (.lit 5)))

def example2 : Expr :=
  .catch (.throw (.lit 42)) (.lit 0)

def example3 : Expr :=
  .tell (.add (.get) (.lit 1))

-- Test the interpreter
#eval run example1 0
#eval run example2 0
#eval run example3 0

end Effects.Examples
