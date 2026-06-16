-- Nondet effect tests
import Effects

open Effects.Core

namespace NondetTest

def testChoice : Effects.Std.Nondet.Free Nat :=
  Effects.Std.Nondet.choice 1 2

theorem testNondetLaws :
  Effects.Std.Nondet.run testChoice = [1, 2] := by
  native_decide

theorem testNondetSimp {α β : Type} (x : α) (f : α → Effects.Std.Nondet.Free β) :
  FreeMonad.bind (FreeMonad.pure x : Effects.Std.Nondet.Free α) f = f x := by
  simp [FreeMonad.bind_pure_simp]

theorem testNondetSimp2 {α : Type} (m : Effects.Std.Nondet.Free α) :
  FreeMonad.bind m FreeMonad.pure = m := by
  simp [FreeMonad.bind_pure_eta]

end NondetTest
