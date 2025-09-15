-- Reader + Writer combination tests
import Effects
import Effects.Std.Reader
import Effects.Std.Writer
import Effects.Compose.Product

namespace ReaderWriterTest

-- Combined Reader + Writer signature
inductive ReaderWriterSig (ρ ω : Type u) (α : Type u) where
  | reader : ReaderSig ρ α → ReaderWriterSig ρ ω α
  | writer : WriterSig ω α → ReaderWriterSig ρ ω α

-- Functor instance for ReaderWriterSig
instance {ρ ω : Type u} : Functor (ReaderWriterSig ρ ω) where
  map f := fun m => match m with
    | .reader fx => .reader (f <$> fx)
    | .writer fx => .writer (f <$> fx)

-- Free monad for Reader + Writer
def ReaderWriter.Free (ρ ω α : Type u) : Type u :=
  FreeMonad (ReaderWriterSig ρ ω) α

-- Operations for Reader + Writer
def ReaderWriter.ask (ρ ω : Type u) : ReaderWriter.Free ρ ω ρ :=
  .impure (.reader .ask) (fun x => .pure x)

def ReaderWriter.tell (ρ ω : Type u) (w : ω) : ReaderWriter.Free ρ ω Unit :=
  .impure (.writer (.tell w)) (fun _ => .pure ())

-- Combined Reader + Writer monad transformer
def ReaderWriterT (ρ ω : Type u) (M : Type u → Type u) [Monad M] [Monoid ω] (α : Type u) : Type u :=
  ρ → M (α × ω)

-- Monad instance for ReaderWriterT
instance [Monad M] [Monoid ω] : Monad (ReaderWriterT ρ ω M) where
  pure x := fun r => pure (x, 1)
  bind m f := fun r => do
    let (x, w1) ← m r
    let (y, w2) ← f x r
    pure (y, w1 * w2)

-- Handler implementation for Reader + Writer
instance [Monad M] [Monoid ω] : Handler (ReaderWriterSig ρ ω) (ReaderWriterT ρ ω M) where
  interpret := fun m => match m with
    | .pure x => fun r => pure (x, 1)
    | .impure fx k => fun r => match fx with
      | .reader fx' => match fx' with
        | .ask => k r r
      | .writer fx' => match fx' with
        | .tell w => k () r >>= fun (x, w') => pure (x, w * w')
  interpret_pure := by simp
  interpret_bind := by
    intro m f
    induction m with
    | pure x => simp
    | impure fx k ih =>
      simp
      cases fx with
      | reader fx' =>
        cases fx' with
        | ask => simp; congr 1; ext y; exact ih y
      | writer fx' =>
        cases fx' with
        | tell w => simp; congr 1; ext y; exact ih y

-- Fusion theorems for Reader + Writer
theorem reader_writer_fusion [Monad M] [Monad N] [Monoid ω] (h : M α → N α) :
  h ∘ interpret = interpret ∘ (h <$> ·) := by
  ext m r
  simp [interpret]
  induction m with
  | pure x => simp [Handler.interpret_pure]
  | impure fx k ih =>
    simp [Handler.interpret_bind]
    cases fx with
    | reader fx' =>
      cases fx' with
      | ask => simp; congr 1; ext y; exact ih y
    | writer fx' =>
      cases fx' with
      | tell w => simp; congr 1; ext y; exact ih y

-- Test reader + writer combination
def testReaderWriter (r : Nat) : ReaderWriter.Free Nat Nat Nat :=
  ReaderWriter.ask Nat Nat >>= fun current =>
    ReaderWriter.tell Nat Nat current >>= fun _ =>
      pure current

-- Test reader + writer laws
theorem testReaderWriterLaws (r : Nat) :
  ReaderWriterT.run (testReaderWriter r) r = (r, r) := by
  simp [testReaderWriter, ReaderWriterT.run, ReaderWriter.ask, ReaderWriter.tell, bind]

-- Run function for ReaderWriterT
def ReaderWriterT.run (m : ReaderWriterT ρ ω M α) (r : ρ) : M (α × ω) :=
  m r

-- Test the implementation
#eval ReaderWriterT.run (testReaderWriter 5) 0
#eval ReaderWriterT.run (testReaderWriter 0) 0

end ReaderWriterTest
