-- State effect tests
import Effects

namespace StateTest

-- Test basic state operations
def testGet : State.Free Nat Nat :=
  State.get Nat

def testPut : State.Free Nat Unit :=
  State.put Nat 42

def testModify : State.Free Nat Unit :=
  State.modify Nat (fun n => n + 1)

def testGets : State.Free Nat Nat :=
  State.gets Nat (fun n => n * 2)

-- Test state laws
theorem testStateLaws (s : Nat) :
  State.run (State.get Nat) s = (s, s) := by
  simp [State.run, State.get]

theorem testPutGet (s : Nat) :
  State.run (State.put Nat s >>= fun _ => State.get Nat) 0 = (s, s) := by
  simp [State.run, State.put, State.get, bind]

theorem testModifyLaws (s : Nat) :
  State.run (State.modify Nat (fun n => n + 1)) s = ((), s + 1) := by
  simp [State.modify, State.run, State.get, State.put, bind]

-- Test state simplification
theorem testStateSimp (x : α) (f : α → State.Free Nat β) :
  bind (pure x : State.Free Nat α) f = f x := by
  simp [bind, FreeMonad.pure_bind]

theorem testStateSimp2 (m : State.Free Nat α) :
  bind m pure = m := by
  simp [bind, FreeMonad.bind_pure]

end StateTest
