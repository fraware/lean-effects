-- Exception effect tests
import Effects

open Effects.Core

namespace ExceptionTest

def testThrow : Effects.Std.Exception.Free String Nat :=
  Effects.Std.Exception.throw (α := Nat) String "error"

theorem testExceptionSimp {α β : Type} (x : α) (f : α → Effects.Std.Exception.Free String β) :
  FreeMonad.bind (FreeMonad.pure x : Effects.Std.Exception.Free String α) f = f x := by
  simp [FreeMonad.bind_pure_simp]

theorem testExceptionSimp2 {α : Type} (m : Effects.Std.Exception.Free String α) :
  FreeMonad.bind m FreeMonad.pure = m := by
  simp [FreeMonad.bind_pure_eta]

end ExceptionTest
