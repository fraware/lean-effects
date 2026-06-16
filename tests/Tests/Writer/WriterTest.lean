-- Writer effect tests
import Effects

open Effects.Core

namespace WriterTest

def testTell : Effects.Std.Writer.Free String PUnit :=
  Effects.Std.Writer.tell String "log"

theorem testWriterSimp {α β : Type} (x : α) (f : α → Effects.Std.Writer.Free String β) :
  FreeMonad.bind (FreeMonad.pure x : Effects.Std.Writer.Free String α) f = f x := by
  simp [FreeMonad.bind_pure_simp]

theorem testWriterSimp2 {α : Type} (m : Effects.Std.Writer.Free String α) :
  FreeMonad.bind m FreeMonad.pure = m := by
  simp [FreeMonad.bind_pure_eta]

end WriterTest
