-- Reader effect tests
import Effects

open Effects.Core

namespace ReaderTest

def testAsk : Effects.Std.Reader.Free Nat Nat :=
  Effects.Std.Reader.ask Nat

theorem testReaderLaws :
  Effects.Std.Reader.run (Effects.Std.Reader.ask Nat) 5 = 5 := by
  native_decide

theorem testReaderSimp {α β : Type} (x : α) (f : α → Effects.Std.Reader.Free Nat β) :
  FreeMonad.bind (FreeMonad.pure x : Effects.Std.Reader.Free Nat α) f = f x := by
  simp [FreeMonad.bind_pure_simp]

theorem testReaderSimp2 {α : Type} (m : Effects.Std.Reader.Free Nat α) :
  FreeMonad.bind m FreeMonad.pure = m := by
  simp [FreeMonad.bind_pure_eta]

end ReaderTest
