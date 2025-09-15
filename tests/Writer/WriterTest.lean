-- Writer effect tests
import Effects

namespace WriterTest

-- Test basic writer operations
def testTell : Writer.Free Nat Unit :=
  Writer.tell Nat 42

-- Test writer laws
theorem testWriterLaws :
  Writer.run (Writer.tell Nat 42) = ((), 42) := by
  simp [Writer.run, Writer.tell]

-- Test writer simplification
theorem testWriterSimp (x : α) (f : α → Writer.Free Nat β) :
  bind (pure x : Writer.Free Nat α) f = f x := by
  simp [bind, FreeMonad.pure_bind]

theorem testWriterSimp2 (m : Writer.Free Nat α) :
  bind m pure = m := by
  simp [bind, FreeMonad.bind_pure]

end WriterTest
