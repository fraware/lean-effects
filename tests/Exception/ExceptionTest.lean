-- Exception effect tests
import Effects

namespace ExceptionTest

-- Test basic exception operations
def testThrow : Exception.Free String Nat :=
  Exception.throw String "error"

-- Test exception laws
theorem testExceptionLaws :
  Exception.run (Exception.throw String "error") = .error "error" := by
  simp [Exception.run, Exception.throw]

-- Test exception simplification
theorem testExceptionSimp (x : α) (f : α → Exception.Free String β) :
  bind (pure x : Exception.Free String α) f = f x := by
  simp [bind, FreeMonad.pure_bind]

theorem testExceptionSimp2 (m : Exception.Free String α) :
  bind m pure = m := by
  simp [bind, FreeMonad.bind_pure]

end ExceptionTest
