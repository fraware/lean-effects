-- Reader effect tests
import Effects

namespace ReaderTest

-- Test basic reader operations
def testAsk : Reader.Free Nat Nat :=
  Reader.ask Nat

-- Test reader laws
theorem testReaderLaws (r : Nat) :
  Reader.run (Reader.ask Nat) r = r := by
  simp [Reader.run, Reader.ask]

-- Test reader simplification
theorem testReaderSimp (x : α) (f : α → Reader.Free Nat β) :
  bind (pure x : Reader.Free Nat α) f = f x := by
  simp [bind, FreeMonad.pure_bind]

theorem testReaderSimp2 (m : Reader.Free Nat α) :
  bind m pure = m := by
  simp [bind, FreeMonad.bind_pure]

end ReaderTest
