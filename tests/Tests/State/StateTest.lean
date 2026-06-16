-- State effect tests
import Effects

open Effects.Core

namespace StateTest

def testGet : Effects.Std.State.Free Nat Nat :=
  Effects.Std.State.get Nat

def testPut : Effects.Std.State.Free Nat PUnit :=
  Effects.Std.State.put Nat 42

theorem testStateLaws :
  Effects.Std.State.run (Effects.Std.State.get Nat) 5 = (5, 5) := by
  native_decide

theorem testStateSimp {α β : Type} (x : α) (f : α → Effects.Std.State.Free Nat β) :
  FreeMonad.bind (FreeMonad.pure x : Effects.Std.State.Free Nat α) f = f x := by
  simp [FreeMonad.bind_pure_simp]

theorem testStateSimp2 {α : Type} (m : Effects.Std.State.Free Nat α) :
  FreeMonad.bind m FreeMonad.pure = m := by
  simp [FreeMonad.bind_pure_eta]

end StateTest
