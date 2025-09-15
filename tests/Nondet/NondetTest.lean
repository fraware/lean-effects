-- Nondet effect tests
import Effects

namespace NondetTest

-- Test basic nondet operations
def testEmpty : Nondet.Free Nat :=
  Nondet.empty

def testChoice : Nondet.Free Nat :=
  Nondet.choice 1 2

-- Test nondet laws
theorem testNondetLaws :
  Nondet.run (Nondet.choice 1 2) = [1, 2] := by
  simp [Nondet.run, Nondet.choice]

-- Test nondet simplification
theorem testNondetSimp (x : α) (f : α → Nondet.Free β) :
  bind (pure x : Nondet.Free α) f = f x := by
  simp [bind, FreeMonad.pure_bind]

theorem testNondetSimp2 (m : Nondet.Free α) :
  bind m pure = m := by
  simp [bind, FreeMonad.bind_pure]

end NondetTest
